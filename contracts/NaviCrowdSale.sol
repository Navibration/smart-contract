pragma solidity ^0.4.24;

import "./NaviCoin.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";

contract NaviCrowdSale is Ownable {
    using SafeMath for uint256;
    
    mapping(address => uint256) participants;

    NaviCoin crowdsaleToken;

    mapping (bytes4 => bool) inUse;

    uint256 public maxSupply;
    uint256 public totalCollected;

    event SellToken(address recepient, uint tokensSold);

    modifier preventReentrance {
        require(!inUse[msg.sig]);
        inUse[msg.sig] = true;
        _;
        inUse[msg.sig] = false;
    }

    constructor(
        NaviCoin _token
    )
    public
    {
        maxSupply = 30000000000000000;
        totalCollected = 1625000000000000;
        crowdsaleToken = _token;
    }

    // returns address of the erc20 navi token
    function getToken()
    public view
    returns(address)
    {
        return address(crowdsaleToken);
    }

    // transfers crowdsale token from mintable to transferrable state
    function releaseTokens()
    public
    onlyOwner()             // manager is CrowdsaleController instance
    {
        crowdsaleToken.release();
    }

    // sels the project's token to buyers
    function generate(
        address _recepient, 
        uint256 _value
    ) public
        preventReentrance
        onlyOwner()        // only manager can call it
    {
        uint256 newTotalCollected = totalCollected.add(_value);

        require(maxSupply >= newTotalCollected);

        // create new tokens for this buyer
        crowdsaleToken.issue(_recepient, _value);

        emit SellToken(_recepient, _value);

        // remember the buyer so he/she/it may refund its ETH if crowdsale failed
        participants[_recepient] = participants[_recepient].add(_value);

        totalCollected = newTotalCollected;
    }

    // project's owner withdraws ETH funds
    function withdraw(
        uint256 _amount, // can be done partially,
        address _recepient
    )
    public
    onlyOwner()
    {
        require(_amount <= address(this).balance);
        _recepient.transfer(_amount);
    }

}