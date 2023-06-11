# AutoLimitXSwap
### _**Create trustless limit orders across EVM chains**_

We have created an automation module for any account abstraction or EOA wallet to be able to create limit orders from any token on any source chain to another token on any destination chain across EVM.

Key Features we kept in mind while building the product -

Trustless - AutoLimitXSwap is a smart contract module, meaning it is completely decentralized, composable, and operates on a trustless system.

Cross-chain - AutoLimitXSwap can be deployed on any EVM-compatible chain, making it possible for users to trade across multiple chains.

Automation - AutoLimitXSwap leverages Chainlink Upkeeps to automate the execution of limit orders. This means that once a user creates a limit order, they no longer need to actively monitor the market to execute the trade.

Composable - AutoLimitXSwap can be easily integrated into other DeFi protocols and AA modules, enabling composability and allowing developers to create more complex trading strategies.

The module is truly composable and trustless any developer can build on top of it to enable cross-chain DeFi automation across any EVM chain of their preference by choosing the protocols they want to interact with.


## What it does & How we built it
AutoLimitXSwap is deployed on Ethereum and Polygon Chain.

When a user creates a limit order, they specify the token pair they want to trade, the price they want to buy or sell at, and the amount of tokens they want to trade.
The limit order is then added to the AutoLimitXSwap order book. We leverage Chainlink Upkeeps to create a proxy task with call data as per the limit order specified by the user's EOA or account abstraction.
When the price of the token pair reaches the user's specified price, the Chainlink Upkeep executes the trade automatically. The user's tokens are then swapped for the desired tokens at the specified price on the desired chain.
For swaps across these chains, we use Connext Protocol to bridge the liquidity and call data from the source chain and execute it on the destination chain
Anyone can create limit orders and DCAs across tokens across Any Chain by using our module.

We also allow verse token limit orders across any chain, put your limit order on the polygon to trade/invest in verse tokens on Ethereum. We handle all swaps, trade, bridging, price checks, etc for you. 
We Support Verse Dex and Verse token limit orders in our module!

Deployed Contract Addresses 
 * <a href="https://mumbai.polygonscan.com/address/0xefb199412B876909737aD8E17C3ff753E8D88B70" target="_blank">Polygon Chain</a>
 * <a href="https://goerli.etherscan.io/address/0xE4a1021Ada4f3541bd404308A8e66474321b87eF" target="_blank">Ethereum Chain</a>
