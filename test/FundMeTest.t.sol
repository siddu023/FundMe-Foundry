//SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFoundMe.s.sol";



contract FundMeTest is Test {
    FundMe fundMe;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;

    address public constant USER = address(1);

    function setUp() external{
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();

        fundMe = deployFundMe.run();

    }

    function testMinmumDollarsIsFive() public{
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testFundFailWithOutEnoughETH() public{
        vm.expectRevert();

        fundMe.fund();
    }
     
     function testAddsFunderToArrayOfFunders() public{
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();
        
        address funder= fundMe.getFunder(0);
        assertEq(funder,USER);
     }
     function testOnlyOwnerCanWithdraw() public{
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}


     }
     


    



}