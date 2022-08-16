//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract priceLimitToken is ERC20, ChainlinkClient, ConfirmedOwner {

    using Chainlink for Chainlink.Request;

    uint256 private priceLimit;
    uint256 public volume;
    bytes32 private jobId;
    uint256 private fee;
    string private pancakeswapAPI;

    event RequestVolume(bytes32 indexed requestId, uint256 volume);

    constructor(uint256 initialSupply) ERC20("PriceLimitToken", "PLT") ChainlinkClient(" ") ConfirmedOwner(msg.sender) {
            _mint(msg.sender, initialSupply);
            setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
            setChainlinkOracle("");
            jobId = 'ca98366cc7314957b8c012c72f05aeeb';
            fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    modifier checkPrice {
        requestVolumeData();
        require(volume > priceLimit);
        _;
    }

    function transfer(address to, uint256 amount) public override checkPrice returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override checkPrice returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function createStrForPancakeSwapApi(string memory api_url ,string memory tokenAddr) private returns(string) {
        string memory concat_api_string = string.concat(api_url, tokenAddr);
        pancakeswapAPI = concat_api_string;
        return pancakeswapAPI;
    }

    function requestVolumeData() public returns (bytes32 requestId) {

        require(bytes(pancakeswapAPI).length > 0, 'Use createStrForPancakeSwapApi to create a request');
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        req.add('get', pancakeswapAPI);

        req.add('path', 'data,price'); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**18;
        req.addInt('times', timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _volume);
        volume = _volume;
    }

    function setPriceLimit(uint256 newPriceLimit) returns(uint256 updatedPriceLimit){

        require(newPriceLimit > 0, 'Should be > 0');
        priceLimit = newPriceLimit;
        return priceLimit;
        
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), 'Unable to transfer');
    }

}
