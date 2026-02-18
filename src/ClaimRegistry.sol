// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VATAToken.sol";
import "./AnchorRegistry.sol";

contract ClaimRegistry {
    VATAToken public immutable token;
    AnchorRegistry public immutable anchors;

    enum Status { NONE, PENDING, CHALLENGED, FRAUD, FINAL }

    struct Claim {
        address submitter;
        bytes32 artifactRoot;
        bytes32 proofBundleRoot;
        uint96  stake;
        uint40  createdAt;
        Status  status;
    }

    mapping(bytes32 => Claim) public claims;

    uint40 public challengeWindow = 1 days;
    uint96 public minStake = 1_000 ether;
    uint96 public minChallengeBond = 500 ether;

    // NEW: require N anchors before FINAL
    uint8 public minAnchors = 3;

    struct Challenge {
        address challenger;
        uint96 bond;
        bool exists;
    }

    mapping(bytes32 => Challenge) public challenges;

    event ClaimSubmitted(bytes32 indexed claimId, address indexed submitter, bytes32 artifactRoot, bytes32 proofBundleRoot, uint96 stake);
    event ClaimChallenged(bytes32 indexed claimId, address indexed challenger, uint96 bond);
    event ClaimFinalized(bytes32 indexed claimId);
    event ClaimSlashed(bytes32 indexed claimId, address indexed challenger, uint256 reward);

    constructor(address tokenAddress, address anchorRegistry) {
        token = VATAToken(tokenAddress);
        anchors = AnchorRegistry(anchorRegistry);
    }

    function setParams(uint40 _challengeWindow, uint96 _minStake, uint96 _minBond, uint8 _minAnchors) external {
        require(_challengeWindow >= 1 hours && _challengeWindow <= 30 days, "bad window");
        require(_minStake > 0 && _minBond > 0, "bad mins");
        require(_minAnchors > 0 && _minAnchors <= 32, "bad anchors");
        challengeWindow = _challengeWindow;
        minStake = _minStake;
        minChallengeBond = _minBond;
        minAnchors = _minAnchors;
    }

    function submitClaim(
        bytes32 claimId,
        bytes32 artifactRoot,
        bytes32 proofBundleRoot,
        uint96 stakeAmount
    ) external {
        require(claimId != bytes32(0), "bad id");
        require(claims[claimId].status == Status.NONE, "exists");
        require(stakeAmount >= minStake, "stake too low");

        require(token.transferFrom(msg.sender, address(this), stakeAmount), "stake transfer failed");

        claims[claimId] = Claim({
            submitter: msg.sender,
            artifactRoot: artifactRoot,
            proofBundleRoot: proofBundleRoot,
            stake: stakeAmount,
            createdAt: uint40(block.timestamp),
            status: Status.PENDING
        });

        emit ClaimSubmitted(claimId, msg.sender, artifactRoot, proofBundleRoot, stakeAmount);
    }

    function challengeClaim(bytes32 claimId, uint96 bondAmount) external {
        Claim storage c = claims[claimId];
        require(c.status == Status.PENDING, "not pending");
        require(block.timestamp <= c.createdAt + challengeWindow, "window closed");
        require(!challenges[claimId].exists, "already challenged");
        require(bondAmount >= minChallengeBond, "bond too low");

        require(token.transferFrom(msg.sender, address(this), bondAmount), "bond transfer failed");

        challenges[claimId] = Challenge({
            challenger: msg.sender,
            bond: bondAmount,
            exists: true
        });

        c.status = Status.CHALLENGED;
        emit ClaimChallenged(claimId, msg.sender, bondAmount);
    }

    // v0 placeholder: slashing not proof-gated yet (next step is VerifierRouter)
    function slashClaim(bytes32 claimId) external {
        Claim storage c = claims[claimId];
        Challenge memory ch = challenges[claimId];

        require(c.status == Status.CHALLENGED, "not challenged");
        require(ch.exists, "no challenge");
        require(block.timestamp <= c.createdAt + challengeWindow, "too late");

        c.status = Status.FRAUD;
        delete challenges[claimId];

        uint256 reward = uint256(c.stake) + uint256(ch.bond);
        require(token.transfer(ch.challenger, reward), "reward transfer failed");

        emit ClaimSlashed(claimId, ch.challenger, reward);
    }

    function finalizeClaim(bytes32 claimId) external {
        Claim storage c = claims[claimId];
        require(c.status == Status.PENDING, "not pending");
        require(block.timestamp > c.createdAt + challengeWindow, "window open");

        // NEW: require cross-chain anchoring quorum
        require(anchors.anchorCount(claimId) >= minAnchors, "insufficient anchors");

        c.status = Status.FINAL;
        require(token.transfer(c.submitter, c.stake), "return transfer failed");

        emit ClaimFinalized(claimId);
    }
}
