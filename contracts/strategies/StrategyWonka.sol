// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

import "@openzeppelinV2/contracts/token/ERC20/IERC20.sol";
import "@openzeppelinV2/contracts/math/SafeMath.sol";
import "@openzeppelinV2/contracts/utils/Address.sol";
import "@openzeppelinV2/contracts/token/ERC20/SafeERC20.sol";

// import "../../interfaces/yearn/IProxy.sol";
// import "../../interfaces/curve/Mintr.sol";

import "../wonka/ERC2746.sol";

contract StrategyWonka {

    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // REFERENCE: IProxy public constant proxy = IProxy(0xF147b8125d2ef93FB6965Db97D6746952a133934);
    address public rulesEngine;
    address public incrAmtTreeOwner;
    address public voteTreeOwner;
    address public withdrawTreeOwner;
    address public transferTreeOwner;
    address public approveTreeOwner;
    address public mintTreeOwner;
    address public depositTreeOwner;

    address public constant mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant gauge = address(0x2F50D538606Fa9EDD2B11E2446BEb18C9D5846bB);
    address public constant y = address(0xFA712EE4788C042e2B7BB55E6cb8ec569C4530c1);

    address public governance;

    constructor(address _engine, address _bOwner, address _iatOwner, address _voteOwner, address _withdrawOwner, address _transOwner, address _approveOwner, address _mintOwner, address _depositOwner) public {
        governance = msg.sender;

        rulesEngine = _engine;
        incrAmtTreeOwner = _iatOwner;
        voteTreeOwner = _voteOwner;
        withdrawTreeOwner = _withdrawOwner;
        transferTreeOwner = _transOwner;
        approveTreeOwner = _approveOwner;
        mintTreeOwner = _mintOwner;
        depositTreeOwner = _depositOwner;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function lock() external {
        uint256 amount = IERC20(crv).balanceOf(rulesEngine);

        if (amount > 0) {

            // REFERENCE: proxy.increaseAmount(amount);
            // ERC2746(rulesEngine).setValueOnRecord(governance, "incAmt", amount);
            ERC2746(rulesEngine).executeRuleTree(incrAmtTreeOwner);
        }
    }

    function vote(address _gauge, uint256 _amount) public {

        // REFERENCE: proxy.execute(gauge, 0, abi.encodeWithSignature("vote_for_gauge_weights(address,uint256)", _gauge, _amount));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "voteGauge", _gauge);
        // ERC2746(rulesEngine).setValueOnRecord(governance, "voteAmt", _amount);
        ERC2746(rulesEngine).executeRuleTree(voteTreeOwner);
    }

    function withdraw(
        address _gauge,
        address _token,
        uint256 _amount
    ) public returns (uint256) {

        uint256 _before = IERC20(_token).balanceOf(rulesEngine);

        // REFERENCE: proxy.execute(_gauge, 0, abi.encodeWithSignature("withdraw(uint256)", _amount));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "withdrawAmt", _amount);
        ERC2746(rulesEngine).executeRuleTree(withdrawTreeOwner);

        uint256 _after = IERC20(_token).balanceOf(rulesEngine);
        uint256 _net = _after.sub(_before);

        // REFERENCE: proxy.execute(_token, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _net));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "withdrawMsgSender", msg.sender);
        // ERC2746(rulesEngine).setValueOnRecord(governance, "withdrawTransferAmt", _net);
        ERC2746(rulesEngine).executeRuleTree(transferTreeOwner);

        return _net;
    }

    function balanceOf(address _gauge) public view returns (uint256) {
        return IERC20(_gauge).balanceOf(rulesEngine);
    }

    function withdrawAll(address _gauge, address _token) external returns (uint256) {
        return withdraw(_gauge, _token, balanceOf(_gauge));
    }

    function deposit(address _gauge, address _token) external {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(rulesEngine, _balance);
        _balance = IERC20(_token).balanceOf(rulesEngine);

        // REFERENCE: proxy.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, 0));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "depGauge", _gauge);
        // ERC2746(rulesEngine).setValueOnRecord(governance, "depBalance", 0);
        ERC2746(rulesEngine).executeRuleTree(approveTreeOwner);
        
        // REFERENCE: proxy.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", _gauge, _balance));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "depGauge", _gauge);
        // ERC2746(rulesEngine).setValueOnRecord(governance, "depBalance", _balance);
        ERC2746(rulesEngine).executeRuleTree(approveTreeOwner);

        // REFERENCE: (bool success, ) = proxy.execute(_gauge, 0, abi.encodeWithSignature("deposit(uint256)", _balance));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "depBalance", _balance);
        ERC2746(rulesEngine).executeRuleTree(depositTreeOwner);

        // NOTE: Alter functionality
        // if (!success) assert(false);
    }

    function harvest(address _gauge) external {
        uint256 _before = IERC20(crv).balanceOf(rulesEngine);
        
        // REFERENCE: proxy.execute(mintr, 0, abi.encodeWithSignature("mint(address)", _gauge));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "harvestGauge", _gauge);
        ERC2746(rulesEngine).executeRuleTree(mintTreeOwner);

        uint256 _after = IERC20(crv).balanceOf(rulesEngine);
        uint256 _balance = _after.sub(_before);

        // REFERENCE: proxy.execute(crv, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _balance));
        // ERC2746(rulesEngine).setValueOnRecord(governance, "harvestMsgSender", msg.Sender);
        // ERC2746(rulesEngine).setValueOnRecord(governance, "harvestBalance", _balance);
        ERC2746(rulesEngine).executeRuleTree(transferTreeOwner);
    }
}
