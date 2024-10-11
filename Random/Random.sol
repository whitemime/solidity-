// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.21;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts@1.2.0/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import "https://github.com/AmazingAng/WTF-Solidity/blob/main/34_ERC721/ERC721.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract SubscriptionConsumer is ERC721,VRFConsumerBaseV2Plus {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);
    uint256 public totalSupply = 100;//总供应量
    uint256 public mintCount;//已铸造的数量
    uint256[100] public ids;//记录可供mint的tokenid
    // 记录VRF申请标识对应的mint地址
    mapping(uint256 => address) public requestToSender;
    //请求状态结构体
    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    //请求id映射请求结构体
    mapping(uint256 => RequestStatus)
        public s_requests; /* requestId --> requestStatus */

    // Your subscription ID.
    //订阅id
    uint256 public s_subscriptionId;

    // Past request IDs.
    //存请求id的数组
    uint256[] public requestIds;
    //最后一个请求id
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2-5/supported-networks
    
    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 public callbackGasLimit = 1000000;

    // The default is 3, but you can set this higher.
    uint16 public requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2_5.MAX_NUM_WORDS.
    uint32 public numWords = 2;

    /**
     * HARDCODED FOR SEPOLIA
     * COORDINATOR: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
     */
    constructor(
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) ERC721("WTF Random", "WTF") {
        s_subscriptionId = subscriptionId;
    }

    // Assumes the subscription is funded sufficiently.
    // @param enableNativePayment: Set to `true` to enable payment in native tokens, or
    // `false` to pay in LINK
    function requestRandomWords(
        bool enableNativePayment
    ) external onlyOwner returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        requestIds.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        requestToSender[requestId] = msg.sender;
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        for(uint i = 0;i < s_requests[_requestId].randomWords.length;i++) {
            uint256 _tokenid = pickRandomUniqueId(s_requests[_requestId].randomWords[i]);
            _mint(msg.sender,_tokenid);
        }
        emit RequestFulfilled(_requestId, _randomWords);
    }
    //利用随机数铸造NFT
    //获取tokenid
    function pickRandomUniqueId(uint256 random) public returns (uint256 tokenId) {
        //还能铸造的数量
        uint256 len = totalSupply - mintCount++;
        require(len > 0);
        //更新ids
        uint256 randomIndex = random % len;//取一个随机索引
        tokenId = ids[randomIndex] != 0 ? ids[randomIndex] : randomIndex;//获得tokenid
        ids[randomIndex] = ids[len - 1] == 0 ? len - 1 : ids[len - 1];//设置上此位置被用过
        ids[len - 1] = 0;
    }
    function getRequestStatus(
        uint256 _requestId
    ) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
    //function myMint() external {
        //require(s_requests[lastRequestId].randomWords.length > 0,"not number");
    //     for(uint i = 0;i < s_requests[lastRequestId].randomWords.length;i++) {
    //         uint256 _tokenid = pickRandomUniqueId(s_requests[lastRequestId].randomWords[i]);
    //         _mint(msg.sender,_tokenid);
    //     }
    // }
}
