pragma solidity ^0.4.24;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/wings-integration/contracts/BasicCrowdsale.sol";
import "./NaviCoin.sol";

contract NaviCrowdSale is BasicCrowdsale {
    using SafeMath for uint256;
    
    // Crowdsale participants
    mapping(address => uint256) participants;

    mapping(address => uint256) whiteList;

    // navis per ETH fixed price
    uint256 buyPrice;

    NaviCoin crowdsaleToken;

    uint256 tokenUnit = (10 ** 16);
    uint256 firstBonus = (1000 * (10 ** 18));
    uint256 secondBonus = (2000 * (10 ** 18));

    mapping (bytes4 => bool) inUse;

    event SellToken(address recepient, uint tokensSold, uint value);

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
    BasicCrowdsale(msg.sender, msg.sender)
    {
        minimalGoal = 2000000000000000000000;
        hardCap = 1170000000000000000000;
        buyPrice = 10000000000000000000000;
        crowdsaleToken = _token;
    }

    // returns address of the erc20 navi token
    function getToken()
    public
    returns(address)
    {
        return address(crowdsaleToken);
    }

    // called by CrowdsaleController to transfer reward part of
    // tokens sold by successful crowdsale to Forecasting contract.
    // This call is made upon closing successful crowdfunding process.
    function mintTokenRewards(
        address _contract,  // Forecasting contract
        uint256 _amount     // agreed part of totalSold which is intended for rewards
    )
    public
    onlyManager() // manager is CrowdsaleController instance
    {
        crowdsaleToken.issue(_contract, _amount);
    }

    // transfers crowdsale token from mintable to transferrable state
    function releaseTokens()
    public
    onlyManager()             // manager is CrowdsaleController instance
    hasntStopped()            // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale was successful
    {
        crowdsaleToken.release();
    }

    function () payable public {
        require(msg.value > 0);
        sellTokens(msg.sender, msg.value);
    }

    // sels the project's token to buyers
    function sellTokens(
        address _recepient, 
        uint256 _value
    ) internal
        preventReentrance
        hasBeenStarted()     // crowdsale started
        hasntStopped()       // wasn't cancelled by owner
        whenCrowdsaleAlive() // in active state
    {
        require(whiteList[_recepient] <= _value);
        uint256 newTotalCollected = totalCollected.add(_value);

        if (hardCap < newTotalCollected) {
            // don't sell anything above the hard cap

            uint256 refund = newTotalCollected.sub(hardCap);
            uint256 diff = _value.sub(refund);

            // send the ETH part which exceeds the hard cap back to the buyer
            _recepient.transfer(refund);
            _value = diff;
            newTotalCollected = totalCollected.add(_value);
        }

        // Apply Navi Sale bonuses
        uint256 valueWithBonus = _value;
        uint256 bonusDiff;
        uint256 currentBonus;
        if (totalCollected < firstBonus) {
            if (newTotalCollected > firstBonus) {
                bonusDiff = newTotalCollected.sub(firstBonus);
                currentBonus = _value.sub(bonusDiff);
                valueWithBonus = valueWithBonus.add(currentBonus.div(100).mul(20));

                if (bonusDiff > secondBonus) {
                    bonusDiff = bonusDiff.sub(secondBonus);
                    currentBonus = _value.sub(bonusDiff);
                    valueWithBonus = valueWithBonus.add(currentBonus.div(100).mul(10));
                    valueWithBonus = valueWithBonus.add(bonusDiff);
                } else {
                    valueWithBonus = valueWithBonus.add(bonusDiff.div(100).mul(10));
                }

            } else {
                valueWithBonus = valueWithBonus.add(bonusDiff.div(100).mul(20));
            }
        } else if (totalCollected < secondBonus) {
            if (newTotalCollected > secondBonus) {
                bonusDiff = newTotalCollected.sub(secondBonus);
                currentBonus = _value.sub(bonusDiff);
                valueWithBonus = valueWithBonus.add(currentBonus.div(100).mul(10));
                valueWithBonus = valueWithBonus.add(bonusDiff);
            } else {
                valueWithBonus = valueWithBonus.add(valueWithBonus.div(100).mul(10));
            }
        }

        // token amount as per price
        uint256 tokensSold = (valueWithBonus.mul(tokenUnit)).div(buyPrice);


        // create new tokens for this buyer
        crowdsaleToken.issue(_recepient, tokensSold);

        emit SellToken(_recepient, tokensSold, _value);

        // remember the buyer so he/she/it may refund its ETH if crowdsale failed
        participants[_recepient] = participants[_recepient].add(_value);

        // update total ETH collected
        totalCollected = totalCollected.add(_value);

        // update total tokens sold
        totalSold = totalSold.add(tokensSold);
    }

    // project's owner withdraws ETH funds to the funding address upon successful crowdsale
    function withdraw(
        uint256 _amount // can be done partially
    )
    public
    onlyOwner() // project's owner
    hasntStopped()  // crowdsale wasn't cancelled
    whenCrowdsaleSuccessful() // crowdsale completed successfully
    {
        require(_amount <= address(this).balance);
        fundingAddress.transfer(_amount);
    }

    function addWalletToWhitelist(address _address, uint256 _maxAmount) public onlyManager() {
        whiteList[_address] = _maxAmount;
    }

    function addManyToWhitelist(address[] _beneficiaries, uint256[] _maxAmounts) public onlyManager() {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whiteList[_beneficiaries[i]] = _maxAmounts[i];
        }
    }

    // backers refund their ETH if the crowdsale was cancelled or has failed
    function refund()
    public
    {
        // either cancelled or failed
        require(stopped || isFailed());

        uint256 amount = participants[msg.sender];

        // prevent from doing it twice
        require(amount > 0);
        participants[msg.sender] = 0;

        msg.sender.transfer(amount);
    }

}