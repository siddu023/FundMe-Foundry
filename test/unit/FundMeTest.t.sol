//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployFundMe} from "../../script/DeployFoundMe.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelperConfig,CodeConstants} from "../../script/HelperConfig.sol";
import {Test,console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";


contract FundMeTest is ZkSyncChainChecker,CodeConstants,StdCheats,Test{
    FundMe public fundMe;
    HelperConfig public helperConfig;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external{
        if(!isZkSyncChain()){
            DeployFundMe deployer = new DeployFundMe();
            (fundMe, helperConfig) = deployer.deployFundMe();
        } else{
            MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS,INITIAL_PRICE);
            fundMe = new FundMe(address(mockPriceFeed));
        }
        vm.deal(USER,STARTING_USER_BALANCE);
    }

    function testPriceFeedSetCorrectly() public skipZkSync {
        address retrivedPriceFeed = address(fundMe.getPriceFeed());

        address expectedPriceFeed = helperConfig.getConfigByChainId(block.chainid).priceFeed;
        assertEq(retrivedPriceFeed,expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public skipZkSync{
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public skipZkSync{
        vm.startPrank(USER);
        fundMe.fund{value:SEND_VALUE}();
        vm.stopPrank();


        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public skipZkSync{
        vm.startPrank(USER);
        fundMe.fund{value:SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }


    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        assert(address(fundMe).balance>0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded skipZkSync{
        vm.expectRevert();
        vm.prank(address(3));
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded skipZkSync{
        //Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

         //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance,0);
        assertEq(
            startingFundMeBalance+startingOwnerBalance,endingOwnerBalance
        );



    }

    
}




     


    



