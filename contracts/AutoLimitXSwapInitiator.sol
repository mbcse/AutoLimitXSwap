// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

pragma abicoder v2;

import {AutomationRegistryInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface2_0.sol";
import {AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IXReceiver} from "@connext/interfaces/core/IXReceiver.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/utils/Strings.sol";



interface WETH9_ {
    function deposit() external payable;

    function withdraw(uint wad) external;
}


struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    bytes checkData;
    bytes offchainConfig;
    uint96 amount;
}

interface KeeperRegistrarInterface {
    function registerUpkeep(
        RegistrationParams calldata requestParams
    ) external returns (uint256);
}


contract AutoLimitXSwapInitiator is IXReceiver, AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    receive() external payable {}

    fallback() external payable {}

    IConnext public immutable connext;
    ISwapRouter public immutable swapRouter;

    uint24 public poolFee1 = 10000;
    uint24 public poolFee2 = 10000;
    uint256 public out;
    address public WETH ;
    address public NATIVE ;

    AggregatorV3Interface internal priceFeed;
    IUniswapV2Router02 public honeySwapRouter2 ;

    uint96 public upkeepFee = 200000000000000000;

    LinkTokenInterface public immutable i_link;
    KeeperRegistrarInterface public immutable i_registrar;
    bytes4 registerSig = KeeperRegistrarInterface.registerUpkeep.selector;

    constructor(
        IConnext _connext,
        ISwapRouter _swapRouter,
        LinkTokenInterface _link,
        KeeperRegistrarInterface _registrar,
        address _wethAddress,
        address _nativeAddress
    )
    {
        connext = _connext;
        swapRouter = _swapRouter;
        owner = msg.sender;
        i_link = _link;
        i_registrar = _registrar;
        WETH = _wethAddress;
        NATIVE = _nativeAddress;
        // priceFeed = AggregatorV3Interface(chainLink);
    }

    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function createTask(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) internal returns (uint256) {
        bytes memory execData = abi.encode(
            _from,
            _to,
            _amount,
            _price,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee,
            _destinationContractAddress
        );

        RegistrationParams memory _upkeepRegistrationParams = RegistrationParams({
            name: string.concat("LimitOrder", Strings.toHexString(_from)),
            upkeepContract: address(this),
            gasLimit: 1000000,
            adminAddress: address(this),
            checkData: execData,
            offchainConfig:"0x",
            amount: upkeepFee,
            encryptedEmail: "0x"
        });


        i_link.approve(address(i_registrar), _upkeepRegistrationParams.amount);

        uint256 id = i_registrar.registerUpkeep(_upkeepRegistrationParams);
        return id;
    }

    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (
            address _from,
            address _to,
            uint256 _amount,
            int256 _price,
            address _fromToken,
            address _toToken,
            uint256 _toChain,
            uint32 destinationDomain,
            uint256 relayerFee,
            address _destinationContractAddress
        ) = abi.decode(checkData, (
            address,
            address,
            uint256,
            int256,
            address,
            address,
            uint256,
            uint32,
            uint256,
            address
        ));
        upkeepNeeded = price >= _price;
        return (upkeepNeeded, checkData);
    }

    function performUpkeep(bytes calldata performData) external override {
         (
            address _from,
            address _to,
            uint256 _amount,
            int256 _price,
            address _fromToken,
            address _toToken,
            uint256 _toChain,
            uint32 destinationDomain,
            uint256 relayerFee,
            address _destinationContractAddress
        ) = abi.decode(performData, (
            address,
            address,
            uint256,
            int256,
            address,
            address,
            uint256,
            uint32,
            uint256,
            address
        ));

        executeLimitOrder(_from, _to, _amount, _price, _fromToken, _toToken, _toChain, destinationDomain, relayerFee, _destinationContractAddress);
    }

    function swapExactInputSingle(
        address _token,
        uint256 amountIn
    )
        public
        returns (
            // address payable _recipient
            uint256 amountOut
        )
    {
        TransferHelper.safeApprove(_token, address(swapRouter), amountIn);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams(
            abi.encodePacked(_token, poolFee1, NATIVE, poolFee2, WETH),
            address(this),
            block.timestamp,
            amountIn,
            0
        );

        amountOut = swapRouter.exactInput(params);
        return amountOut;

        // address payable recipient  = payable(0x6d4b5acFB1C08127e8553CC41A9aC8F06610eFc7);
        // WETH9_(WETH).withdraw(amountOut);
        // _recipient.transfer(amountOut);
    }

    function xTransfer(
        address recipient,
        uint32 destinationDomain,
        address tokenAddress,
        uint256 amount,
        uint256 slippage,
        uint256 relayerFee,
        address _destinationContractAddress,
        address _toToken
    ) public payable {
        IERC20 token = IERC20(tokenAddress);
        // This contract approves transfer to Connext
        token.approve(address(connext), amount);

        bytes memory exdata = abi.encode(recipient, _toToken);
        connext.xcall{value: relayerFee}(
            destinationDomain, // _destination: Domain ID of the destination chain
            _destinationContractAddress, // _to: address receiving the funds on the destination
            tokenAddress, // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            amount, // _amount: amount of tokens to transfer
            slippage, // _slippage: the maximum amount of slippage the user will accept in BPS
            exdata // _callData: empty because we're only sending funds
        );
    }

    function executeOrder(
        address _from,
        address _to,
        uint256 _amount,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) public payable {
        require(_amount > 0, "Amount must be greater than 0");
        require(_fromToken != _toToken, "From and To tokens must be different");
        require(_toChain > 0, "To chain must be greater than 0");

        // IERC20 token = IERC20(_fromToken);

        // require(
        //     token.allowance(msg.sender, address(this)) >= _amount,
        //     "User must approve amount"
        // );

        // User sends funds to this contract
        // token.transferFrom(msg.sender, address(this), _amount);

        uint256 slippage = 300;
        // token - weth

        uint256 amountOut = swapExactInputSingle(_fromToken, _amount);

        xTransfer(
            _to,
            destinationDomain,
            WETH,
            amountOut,
            slippage,
            relayerFee,
            _destinationContractAddress,
            _toToken
        );

        emit Action(
            DepositCounter,
            "Deposit CREATED & EXECUTED",
            true,
            _from,
            block.timestamp
        );
    }

    function executeMultipleOrderToMany(
        address _from,
        address _to,
        uint256[] calldata _amounts,
        address _fromToken,
        address[] calldata _toTokens,
        uint256 _toChain,
        uint32 _destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) public payable {
        for (uint256 i = 0; i < _amounts.length; i++) {
            executeOrder(
                _from,
                _to,
                _amounts[i],
                _fromToken,
                _toTokens[i],
                _toChain,
                _destinationDomain,
                relayerFee,
                _destinationContractAddress
            );
        }
    }

    function executeMultipleOrderToOne(
        address _from,
        address _to,
        uint256[] calldata _amounts,
        address[] calldata _fromTokens,
        address _toToken,
        uint256 _toChain,
        uint32 _destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) public payable {
        for (uint256 i = 0; i < _amounts.length; i++) {
            executeOrder(
                _from,
                _to,
                _amounts[i],
                _fromTokens[i],
                _toToken,
                _toChain,
                _destinationDomain,
                relayerFee, 
                _destinationContractAddress
            );
        }
    }

    address public owner;
    uint256 public activeDepositCounter = 0;
    uint256 public inactiveDepositCounter = 0;
    uint256 private DepositCounter = 0;

    // mapping(uint256 => address) public delDepositOf;
    mapping(uint256 => address) public authorOf;
    mapping(address => uint256[]) public DepositsOf;

    struct DepositStruct {
        uint256 DepositId;
        address from;
        address to;
        uint256 amount;
        int256 price;
        address fromToken;
        address toToken;
        uint256 toChain;
        bool isActive;
        uint256 created;
        uint256 updated;
    }

    DepositStruct[] activeDeposits;
    DepositStruct[] inactiveDeposits;

    event Action(
        uint256 indexed DepositId,
        string indexed actionType,
        bool isActive,
        address indexed author,
        uint256 timestamp
    );

    modifier ownerOnly() {
        require(msg.sender == owner, "Owner reserved only");
        _;
    }

    error CONDITION_NOT_MET(int, int);

    int256 public price = 100;

    function changePrice(int256 _price) public ownerOnly {
        price = _price;
    }

    function executeLimitOrder(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) public payable {
        // int price = getLatestPrice();
        if (price <= _price) {
            revert CONDITION_NOT_MET(price, _price);
        }

        executeOrder(
            _from,
            _to,
            _amount,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee,
            _destinationContractAddress
        );

        
    }

    function createDeposit(
        address _from,
        address _to,
        uint256 _amount,
        int256 _price,
        address _fromToken,
        address _toToken,
        uint256 _toChain,
        uint32 destinationDomain,
        uint256 relayerFee,
        address _destinationContractAddress
    ) external payable returns (bool) {
        DepositCounter++;
        authorOf[DepositCounter] = _from;
        DepositsOf[_from].push(DepositCounter);
        activeDepositCounter++;

        createTask(
            _from,
            _to,
            _amount,
            _price,
            _fromToken,
            _toToken,
            _toChain,
            destinationDomain,
            relayerFee,
            _destinationContractAddress
        );

        activeDeposits.push(
            DepositStruct(
                DepositCounter,
                _from,
                _to,
                _amount,
                _price,
                _fromToken,
                _toToken,
                _toChain,
                true,
                block.timestamp,
                block.timestamp
            )
        );

        emit Action(
            DepositCounter,
            "Deposit CREATED",
            true,
            _from,
            block.timestamp
        );

        return true;
    }

    function showDepositsOfUser(
        address _user
    ) external view returns (uint256[] memory) {
        return DepositsOf[_user];
    }

    function showDeposit(
        uint256 DepositId
    ) external view returns (DepositStruct memory) {
        DepositStruct memory Deposit;
        for (uint i = 0; i < activeDeposits.length; i++) {
            if (activeDeposits[i].DepositId == DepositId) {
                Deposit = activeDeposits[i];
            }
        }
        return Deposit;
    }

    function getDeposits() external view returns (DepositStruct[] memory) {
        return activeDeposits;
    }

    function getDeletedDeposit()
        external
        view
        ownerOnly
        returns (DepositStruct[] memory)
    {
        return inactiveDeposits;
    }

    function removeElement(address key, uint index) internal {
        require(index < DepositsOf[key].length);
        DepositsOf[key][index] = DepositsOf[key][DepositsOf[key].length - 1];
        DepositsOf[key].pop();
    }

    function deleteDeposit(
        uint256 DepositId,
        address _from
    ) external returns (bool) {
        require(authorOf[DepositId] == _from, "Unauthorized entity");

        for (uint i = 0; i < activeDeposits.length; i++) {
            if (activeDeposits[i].DepositId == DepositId) {
                activeDeposits[i].isActive = false;
                activeDeposits[i].updated = block.timestamp;
                inactiveDeposits.push(activeDeposits[i]);
                // delDepositOf[DepositId] = authorOf[DepositId];
                delete activeDeposits[i];
                delete authorOf[DepositId];
            }
        }
        removeElement(_from, DepositId);
        inactiveDepositCounter++;
        activeDepositCounter--;

        emit Action(
            DepositId,
            "Deposit DELETED",
            false,
            _from,
            block.timestamp
        );

        return true;
    }

    function setHoneySwapRouter2(address _RouterAddress) public ownerOnly {
        honeySwapRouter2 = IUniswapV2Router02(_RouterAddress);
    }

     function setWethAddress(address wethAddress) public ownerOnly {
        WETH = wethAddress;
    }

    function setNativeAddress(address nativeAddress) public ownerOnly {
        NATIVE = nativeAddress;
    }

    function setPoolFee1(uint24 _poolFee1) public ownerOnly {
        poolFee1 = _poolFee1;
    }

    function setPoolFee2(uint24 _poolFee2) public ownerOnly {
        poolFee2 = _poolFee2;
    }

    function setUpkeepFee(uint96 _upkeepFee) public ownerOnly {
        upkeepFee = _upkeepFee;
    }


    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
  ) external returns (bytes memory) {
    // Unpack the _callData
       (address reciepient, address tokenAddress) = abi.decode(_callData, (address, address));

        // IERC20 token = IERC20(WETH);
        // This contract approves transfer to Connext
        // token.approve(address(honeySwapRouter2), _amount);
        // address[] memory path = new address[](2);
        // path[0] = WETH;
        // path[1] = tokenAd;

        TransferHelper.safeApprove(WETH, address(swapRouter), _amount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH,
                tokenOut: tokenAddress,
                fee: poolFee2,
                recipient: reciepient,
                deadline: block.timestamp + 3600,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = swapRouter.exactInputSingle(params);
        return "";
  }
}
