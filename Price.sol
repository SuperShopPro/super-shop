// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPairInfo {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract Price {
    using SafeMath for uint;
    using SafeMath for uint112;

    address public _owner;
    uint256 public staticPrice;

    constructor() {
        _owner = msg.sender;
    }

    function tokenAmount(address pairAddress, address settleToken, uint256 price) external view returns(uint256){
        if(staticPrice == 1){
            return price;
        }
        try this._getTokenPrice(pairAddress, settleToken) returns (uint256 _tokenPrice) {
            return price.mul(_tokenPrice).div(10**18);
        } catch {
            return 0;
        }
    }

    function tokenPrice(address pairAddress, address settleToken) external view returns(uint256){
        try this._getTokenPrice(pairAddress, settleToken) returns (uint256 _tokenPrice) {
            return _tokenPrice;
        } catch {
            return 0;
        }
    }

    function _getTokenPrice(address pairAddress, address settleToken) public view returns(uint256){
        if(pairAddress == address(0)){
            return 0;
        }
        IPairInfo pair = IPairInfo(pairAddress);
        address token0 = pair.token0();
        address token1 = pair.token1();
        if(token0 != settleToken && token1 != settleToken){
            return 0;
        }
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if(reserve0 == 0 || reserve1 == 0){
            return 0;
        }
        if(settleToken == token1){
            return uint256(reserve1.div(reserve0.div(10**18)));
        } else {
            return uint256(reserve0.div(reserve1.div(10**18)));
        }
    }

    function setPriceMode(uint256 _mode) external virtual returns(bool){
        require(msg.sender == _owner, 'Tip: 001');
        staticPrice = _mode;
        return true;
    }
}
