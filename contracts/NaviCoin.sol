pragma solidity ^0.4.18;
import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract NaviCoin is Ownable, StandardToken {
    // ERC20 requirements
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    // 2 states: mintable (initial) and transferrable
    bool public releasedForTransfer;

    event Issue(address recepient, uint amount);

    function NaviCoin() public {
        name = "NAVI COIN";
        symbol = "NAVI";
        decimals = 8;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(releasedForTransfer);
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(releasedForTransfer);
        return super.transferFrom(_from, _to, _value);
    }

    // transfer the state from intable to transferrable
    function release() public onlyOwner() {
        releasedForTransfer = true;
    }

    // creates new amount of navis
    function issue(address _recepient, uint256 _amount) public onlyOwner() {
        require (!releasedForTransfer);
        balances[_recepient] += _amount;
        totalSupply += _amount;
        Issue(_recepient, _amount);
    }
}