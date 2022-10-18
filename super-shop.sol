// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import './Price.sol';

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function join(slice memory self, slice[] memory parts)
    internal
    pure
    returns (string memory)
    {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }

    function _stringToBytes(string memory source)
    internal
    pure
    returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _stringEq(string memory a, string memory b) internal pure returns (bool) {
        if ((bytes(a).length == 0 && bytes(b).length == 0)) {
            return true;
        }
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return _stringToBytes(a) == _stringToBytes(b);
        }
    }
}

library Utils {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function sameDay(uint256 day1, uint256 day2) internal pure returns (bool) {
        return day1 / 24 / 3600 == day2 / 24 / 3600;
    }

    function bytes32Eq(bytes32 a, bytes32 b) internal pure returns (bool) {
        for (uint256 i = 0; i < 32; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }
        return true;
    }

    function bytes32ToString(bytes32 x) internal pure returns (string memory) {
        uint256 charCount = 0;
        bytes memory bytesString = new bytes(32);
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            } else if (charCount != 0) {
                break;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    function _stringToBytes(string memory source)
    internal
    pure
    returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _stringEq(string memory a, string memory b) internal pure returns (bool) {
        if ((bytes(a).length == 0 && bytes(b).length == 0)) {
            return true;
        }

        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return _stringToBytes(a) == _stringToBytes(b);
        }
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract CodeService {
    function encode(uint64 n) public pure returns (string memory) {
        string memory code = Strings.toString(n);
        return code;
    }
    function decode(string memory code) public pure returns (uint256){
        return strToUint(code);
    }
    function strToUint(string memory _str) private pure returns(uint256 res) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        return res;
    }
}

contract Config {
    // 1e22 = 10000*(10**18)
    uint256 constant star1_little_total = 100e22;

    uint256 constant star2_little_total = 200e22;

    uint256 constant star3_little_total = 300e22;

    uint256 constant star4_little_total = 400e22;

    uint256 constant star5_little_total = 500e22;
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract ShangZH is Ownable, Config {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private factory;
    uint256 private constant DAY = 24 * 60 * 60;
    uint256 private constant MAXLEVEL = 10;
    uint256 private N = 99967;
    uint256 private constant D = 100000;
    address public settleToken;

    struct Investor {
        string code;
        address investorAddr;
        uint256 refereeId;
        uint256 largeAreaId;
        uint256 value;
        uint256 rebate;
        uint256 shareAmount;
        uint256 canDrawupAmount;
        uint256 returnAmount;
        uint256 index;
        uint256 achievement;
        uint256 star;
        uint256 drawFund;
    }

    mapping(uint256 => uint256) private recommendProfitMaps;
    mapping(uint256 => uint256) private starProfitMaps;
    mapping(uint256 => uint256) public fundProfitMaps;

    mapping(address => uint256) private indexs;
    Investor[] private investors;

    uint256[] private lastIndexs;
    uint256[] private lastTimestamps;

    uint256 private closureTime;
    uint256 private guaranteeFund;
    CodeService private codeService;

    address private share1 = 0x0f149cf4eA7ffB66D5af3C88133aD97101F971c2;
    address private share3 = 0xd3F94f9c894110b1b36c633E19504a0D38f4Fb2b;
    address public pairAddress;
    address public priceUtilAddress;
    uint256 public uPrice = 700;

    constructor(
        address _codeServiceAddr,
        address _settleToken
    ) {
        factory = msg.sender;
        _insert(0, address(0));
        codeService = CodeService(_codeServiceAddr);
        closureTime = 0;
        guaranteeFund = 0;
        settleToken = _settleToken;
    }

    function setPairAddress(address _pairAddress, address _priceUtilAddress) external virtual returns(bool){
        require(msg.sender == factory, 'Tip: 0012');
        pairAddress = _pairAddress;
        priceUtilAddress = _priceUtilAddress;
        return true;
    }
    function setParams(uint256 _uPrice, uint256 _N) external virtual returns(bool){
        require(msg.sender == factory, 'Tip: 0012');
        uPrice = _uPrice;
        N = _N;
        return true;
    }

    function registerNode(address addr) public onlyOwner {
        require(!Utils.isContract(addr), 'Tip: 0005');
        uint256 id = indexs[addr];
        require(id == 0, "address is exists");
        _insert(investors.length-1, addr);
    }

    function registerNodeByParent(address addr, uint256 parentCode) public onlyOwner {
        require(!Utils.isContract(addr), 'Tip: 0005');
        uint256 id = indexs[addr];
        require(id == 0, "address is exists");
        uint256 refereeId = parentCode;
        _insert(refereeId, addr);
    }

    function info()
    public
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        string memory
    )
    {
        string memory luckyCodes = "";
        if (closureTime != 0) {
            strings.slice[] memory parts = new strings.slice[](lastIndexs.length);
            for (uint256 i = 0; i < lastIndexs.length; i++) {
                parts[i] = strings.toSlice(codeService.encode(uint64(lastIndexs[i])));
            }
            luckyCodes = strings.join(strings.toSlice(" "), parts);
        }

        return (
        IERC20(settleToken).balanceOf(address(this)),
        guaranteeFund,
        closureTime,
        investors.length,
        luckyCodes
        );
    }

    function details(address user) public view returns (
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        uint256 id = indexs[user];
        Investor memory i = investors[id];
        string memory refereeCode;
        if (i.refereeId != 0) {
            refereeCode = codeService.encode(uint64(i.refereeId));
        }

        uint256 largeAchievement;
        string memory largeAreaCode;
        if (i.largeAreaId != 0) {
            largeAreaCode = codeService.encode(uint64(i.largeAreaId));
            largeAchievement = investors[i.largeAreaId].achievement.add(
                _principal(i.largeAreaId)
            );
        }

        return (
        i.code,
        refereeCode,
        largeAreaCode,
        i.star,
        _principal(id),
        i.achievement,
        largeAchievement,
        recommendProfitMaps[id],
        starProfitMaps[id],
        i.shareAmount
        );
    }

    function detailsIncome(address user) public view returns (
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        uint256 id = indexs[user];
        Investor memory i = investors[id];

        uint256 points = 0;
        uint256 canDrawupAmount = 0;
        uint256 returnAmount = 0;
        uint256 dayIncome = 0;
        uint256 index = block.timestamp / DAY;

        if (i.index < index) {
            uint256 remainder = _remainderPoints(id);
            uint256 profile = _sumN(remainder, index - i.index);

            if (remainder < profile) {
                profile = remainder;
            }

            returnAmount = i.returnAmount.add(profile);
            canDrawupAmount = i.canDrawupAmount.add(profile);
            points = _enlarge(i.value).sub(returnAmount);
        } else {
            canDrawupAmount = i.canDrawupAmount;
            returnAmount = i.returnAmount;
            points = _remainderPoints(id);
        }

        dayIncome = (points * (D - N)) / D;

        if(closureTime != 0){
            canDrawupAmount = 0;
            if(closureTime < block.timestamp){
                (bool lucky, uint256 lastValue) = contains(id);
                if (lucky && lastValue > 0 && i.drawFund == 0) {
                    uint256 totalValue = allValue();
                    if (totalValue == 0) {
                        canDrawupAmount = guaranteeFund.mul(lastValue).div(allValue2());
                    }else{
                        canDrawupAmount = guaranteeFund.mul(lastValue).div(totalValue);
                    }
                }
            }
        }

        return (
        points,
        canDrawupAmount,
        returnAmount,
        dayIncome
        );
    }

    function withdraw() public {
        uint256 id = indexs[msg.sender];
        require(id != 0 && id < investors.length);
        uint256 value = 0;
        Investor storage investor = investors[id];
        uint256 rmb2mwarPrice = getMwarPrice();
        if(closureTime == 0){
            _payStaticProfit(id);
            uint settleTokenBalance = IERC20(settleToken).balanceOf(address(this));
            uint rmbBalance = settleTokenBalance.mul(10**18).div(rmb2mwarPrice);
            require(investor.canDrawupAmount <= rmbBalance, 'Tip: 0006');

            value = investor.canDrawupAmount;
            if (rmbBalance.sub(value) <= guaranteeFund) {
                closureTime = block.timestamp + DAY;
                if(rmbBalance >= guaranteeFund){
                    value = rmbBalance.sub(guaranteeFund);
                }else{
                    value = 0;
                    guaranteeFund = rmbBalance;
                }
            }

            investor.canDrawupAmount = investor.canDrawupAmount.sub(value);
        }else{
            if(block.timestamp > closureTime){
                (bool lucky, uint256 lastValue) = contains(id);
                if (lucky && lastValue > 0 && investor.drawFund == 0) {
                    uint256 totalValue = allValue();
                    if (totalValue == 0) {
                        value = guaranteeFund.mul(lastValue).div(allValue2());
                    }else{
                        value = guaranteeFund.mul(lastValue).div(totalValue);
                    }

                    fundProfitMaps[id] = value;
                    investor.drawFund = 1;
                }
            }
        }

        if(value != 0){
            uint256 mwarValue = value.mul(rmb2mwarPrice).div(10**18);
            IERC20(settleToken).safeTransfer(share1, mwarValue.mul(10).div(100));
            IERC20(settleToken).safeTransfer(msg.sender, mwarValue.mul(90).div(100));
        }
    }

    function investByOther(address investorAddr, uint amount) public {
        require(closureTime == 0, 'Tip: 0007');
        // require(Utils._stringEq(SERO, sero_msg_currency()));
        require(!Utils.isContract(msg.sender), 'Tip: 0008');
        require(amount >= 1e18);

        require(msg.sender != investorAddr, 'Tip: 0009');
        uint256 refereeId = indexs[msg.sender];
        require(refereeId != 0 && refereeId < investors.length, 'Tip: 0010');

        uint256 index = indexs[investorAddr];
        if (index == 0) {
            index = _insert(refereeId, investorAddr);
        }

        _investment(index, amount);
    }

    function investByCode(string memory code, uint amount) public {
        require(closureTime == 0, 'Tip: 0011');
        // require(Utils._stringEq(SERO, sero_msg_currency()));
        require(!Utils.isContract(msg.sender), 'Tip: 0001');
        require(amount >= 1e18, 'Tip: 0002');

        uint256 index = indexs[msg.sender];
        if (index == 0) {
            uint256 refereeId;
            if (!Utils._stringEq("", code)) {
                refereeId = codeService.decode(code);
            }
            require(refereeId != 0 && refereeId < investors.length, 'Tip: 0003');
            index = _insert(refereeId, msg.sender);
        }

        _investment(index, amount);
    }

    function _investment(uint256 id, uint256 value) internal {
        uint256 rmb2mwarPrice = getMwarPrice();
        uint256 mwarValue = value.mul(rmb2mwarPrice).div(10**18);
        IERC20(settleToken).safeTransferFrom(msg.sender, address(this), mwarValue);
        IERC20(settleToken).safeTransfer(share3, mwarValue.mul(5).div(100));

        Investor storage investor = investors[id];
        if (investor.value != 0) {
            _payStaticProfit(id);

            uint256 profit = _enlarge(value).mul(D - N) / D;
            investor.canDrawupAmount = investor.canDrawupAmount.add(profit);
            investor.returnAmount = investor.returnAmount.add(profit);
        }

        investor.value = investor.value.add(value);

        uint256 currentId = investor.refereeId;
        uint256 childId = id;

        if (currentId != 0 && _remainderPoints(currentId) > 0) {
            investors[currentId].shareAmount = investors[currentId].shareAmount.add(value);
        }
        while (currentId != uint256(0)) {
            investors[currentId].achievement = investors[currentId].achievement.add(value);

            if (investors[currentId].largeAreaId == 0) {
                investors[currentId].largeAreaId = childId;
            } else {
                uint256 largeAreaId = investors[currentId].largeAreaId;
                uint256 largeAchievement = investors[largeAreaId].achievement.add(_principal(largeAreaId));
                uint256 childAchievement = investors[childId].achievement.add(_principal(childId));

                if ( investors[currentId].largeAreaId != childId && childAchievement > largeAchievement)
                {
                    investors[currentId].largeAreaId = childId;
                    largeAchievement = childAchievement;
                }

                if (currentId == 1) {
                    largeAchievement = 0;
                }

                // uint256 littleAchievement = investors[currentId].achievement.sub(largeAchievement);
                uint256 star = 0;

                if (largeAchievement >= star5_little_total) {
                    star = 5;
                } else if (largeAchievement >= star4_little_total) {
                    star = 4;
                } else if (largeAchievement >= star3_little_total) {
                    star = 3;
                } else if (largeAchievement >= star2_little_total) {
                    star = 2;
                } else if (largeAchievement >= star1_little_total) {
                    star = 1;
                }else {
                    star = 0;
                }

                if (star != investors[currentId].star) {
                    investors[currentId].star = star;
                }
            }

            (childId, currentId) = (currentId, investors[currentId].refereeId);
        }
        _starProfit(investor.refereeId, value);
        _recommendProfit(investor.refereeId, value);

        if(_principal(id) >= 2e22  && investor.returnAmount < _principal(id)){
            addLast(id);
        }

        if(guaranteeFund < 1e25){
            guaranteeFund = guaranteeFund.add(value.div(50));
            if(guaranteeFund > 1e25){
                guaranteeFund = 1e25;
            }
        }

        /*uint256 marketValue = value.div(100);
        uint256 market2Value = value.mul(3).div(100);
        require(sero_send_token(marketAddr, SERO, marketValue));
        require(sero_send_token(marketAddr2, SERO, market2Value));
        require(sero_send_token(owner, SERO, marketValue));*/
    }

    function _insert(uint256 refereeId, address investorAddr)
    internal
    returns (uint256)
    {
        string memory code;
        uint256 index = investors.length;
        if(index != 0){
            indexs[investorAddr] = index;
            code = codeService.encode(uint64(index));
        }else{
            code = "";
        }

        investors.push(
            Investor({
        code: code,
        investorAddr: investorAddr,
        refereeId: refereeId,
        largeAreaId: 0,
        value: 0,
        rebate: 0,
        shareAmount: 0,
        canDrawupAmount: 0,
        returnAmount: 0,
        index: block.timestamp / DAY - 1,
        achievement: 0,
        star: 0,
        drawFund: 0
        })
        );
        return index;
    }

    function _starProfit(uint256 id, uint256 amount) internal {
        _starProfit0(id, amount);
        _starProfit1(id, amount);
    }

    function _starProfit0(uint256 id, uint256 amount) internal {
        if (id == 0) {
            return;
        }

        uint256 rate = 0;
        while (id != 0 && rate < 15) {
            if (investors[id].star == 0) {
                id = investors[id].refereeId;
                continue;
            }

            uint256 currentRate = investors[id].star.mul(3);
            if (currentRate <= rate) {
                id = investors[id].refereeId;
                continue;
            }

            (rate, currentRate) = (currentRate, currentRate - rate);
            uint256 profit = amount.mul(currentRate).div(100);
            _payDynamicProfit(id, profit, false);

            id = investors[id].refereeId;
        }
    }

    function _starProfit1(uint256 id, uint256 amount) internal {
        uint256 star5 = 0;
        while (id != 0) {
            if ((investors[id].star == 5 || id == 1) && star5 <= 3) {
                star5++;
                if (star5 == 2 || star5 == 3) {
                    _payDynamicProfit(id, amount.div(100), false);
                }
            }
            id = investors[id].refereeId;
        }
    }
    
    function _recommendProfit(uint256 firstId, uint256 amount) internal {
        uint256 layer = 1;
        uint256 currentId = firstId;
        // layer 1-5
        while (currentId != uint256(0) && layer <= 5) {
            if (
                investors[currentId].shareAmount.div(1e21) >= layer ||
                _principal(currentId).div(1e21) >= layer ||
                layer == 1 ||
                currentId == 1
            ) {
                // _payRecommendProfit(currentId, amount, 6 - layer);
                _payRecommendProfit(currentId, amount, currentId == firstId ? 10 : 5);
                layer += 1;
            }

            currentId = investors[currentId].refereeId;
        }
        // layer 5-10
        while (currentId != uint256(0) && layer <= 10) {
            if (
                investors[currentId].shareAmount.div(1e21) >= layer ||
                _principal(currentId).div(1e21) >= layer ||
                layer == 1 ||
                currentId == 1
            ) {
                // _payRecommendProfit(currentId, amount, layer - 5);
                _payRecommendProfit(currentId, amount, 5);
                layer += 1;
            }

            currentId = investors[currentId].refereeId;
        }
    }

    function _payRecommendProfit(
        uint256 id,
        uint256 amount,
        uint256 rate
    ) internal {
        uint256 profile = amount.mul(rate).div(100);
        _payDynamicProfit(id, profile, true);
    }

    function _payDynamicProfit(
        uint256 id,
        uint256 value,
        bool flag
    ) private {
        _payStaticProfit(id);

        if (flag) {
            recommendProfitMaps[id] = recommendProfitMaps[id].add(value);
        } else {
            starProfitMaps[id] = starProfitMaps[id].add(value);
        }

        investors[id].value = investors[id].value.add(value);
    }

    function _payStaticProfit(uint256 id) internal {
        Investor storage investor = investors[id];
        uint256 index = block.timestamp / DAY;
        if (investor.index < index) {
            uint256 remainder = _remainderPoints(id);
            if (remainder == 0) {
                investor.index = index;
                return;
            }
            uint256 profit = _sumN(remainder, index - investor.index);
            investor.index = index;

            if (remainder < profit) {
                profit = remainder;
            }

            investor.returnAmount = investor.returnAmount.add(profit);
            investor.canDrawupAmount = investor.canDrawupAmount.add(profit);
        }
    }

    function _remainderPoints(uint256 id) internal view returns (uint256) {
        Investor storage investor = investors[id];
        return _enlarge(investor.value).sub(investor.returnAmount);
    }

    function _principal(uint256 id) internal view returns (uint256) {
        return investors[id].value.sub(recommendProfitMaps[id]).sub(starProfitMaps[id]);
    }

    function _an(uint256 a1, uint256 n) internal view returns (uint256 an) {
        if (n == 0) {
            return a1;
        }

        uint256 m = n / 10;
        uint256 remainder = n % 10;

        for (uint256 i = 0; i < m; i++) {
            an = a1.mul(N**9).div(D**9);
            a1 = (an * N) / D;
        }

        if (remainder > 0) {
            an = a1.mul(N**(remainder - 1)).div(D**(remainder - 1));
        }
    }

    function _sumN(uint256 a1, uint256 n) internal view returns (uint256 sum) {
        if (n == 0) {
            return (0);
        }

        uint256 m = n / 10;
        uint256 remainder = n % 10;

        uint256 an;

        for (uint256 i = 0; i < m; i++) {
            an = a1.mul(N**9).div(D**9);
            sum = sum.add(a1.sub(an.mul(N).div(D)));
            a1 = (an * N) / D;
        }

        if (remainder > 0) {
            an = a1.mul(N**(remainder - 1)).div(D**(remainder - 1));
            sum = sum.add(a1.sub(an.mul(N).div(D)));
        }

        return (sum);
    }

    function _enlarge(uint256 value) internal pure returns (uint256) {
        return value.mul(10);
    }

    function contains(uint256 id) internal view returns (bool flag, uint256 amount) {
        for (uint256 i = 0; i < lastIndexs.length; i++) {
            if (lastIndexs[i] == id) {
                flag = true;
                amount = 0;
                Investor storage investor = investors[lastIndexs[i]];
                uint256 principal = _principal(lastIndexs[i]);
                if(principal > investor.returnAmount){
                    amount = principal;
                }
                break;
            }
        }
    }

    function allValue() internal view returns (uint256 all){
        for (uint256 i = 0; i < lastIndexs.length; i++) {
            Investor storage investor = investors[lastIndexs[i]];
            uint256 principal = _principal(lastIndexs[i]);
            if(principal > investor.returnAmount){
                all += principal;
            }
        }
        return all;
    }

    function allValue2() internal view returns (uint256 all){
        for (uint256 i = 0; i < lastIndexs.length; i++) {
            uint256 principal = _principal(lastIndexs[i]);
            all += principal;
        }
        return all;
    }

    function addLast(uint256 id) internal {
        if (lastIndexs.length == 500) {
            uint256 index = 0;
            uint256 mint = lastTimestamps[0];
            for (uint256 i = 1; i < lastIndexs.length; i++) {
                if (lastIndexs[i] == id) {
                    lastTimestamps[i] = block.timestamp;
                    return;
                }

                Investor storage investor = investors[lastIndexs[i]];
                if(investor.returnAmount >= _principal(lastIndexs[i])){
                    index = i;
                    break;
                }

                if (lastTimestamps[i] < mint) {
                    mint = lastTimestamps[i];
                    index = i;
                }
            }
            lastIndexs[index] = id;
            lastTimestamps[index] = block.timestamp;
        } else {
            lastIndexs.push(id);
            lastTimestamps.push(block.timestamp);
        }
    }

    function getMwarPrice() public view returns(uint256){
        Price priceUtil = Price(priceUtilAddress);
        uint256 u2mwarPrice = priceUtil.tokenPrice(pairAddress, settleToken);
        uint256 rmb2mwarPrice = u2mwarPrice.mul(100).div(uPrice);
        return rmb2mwarPrice;
    }
}
