// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

/// @title An Ethereum library that contains useful routines for the Wonka engine
/// @author Aaron Kendall
library WonkaLibrary {

    /// @dev This method will convert a bytes32 type to a String
    /// @notice 
    function bytes32ToString(bytes32 x) public pure returns (string memory) {

        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }

        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint k = 0; k < charCount; k++) {
            bytesStringTrimmed[k] = bytesString[k];
        }

        return string(bytesStringTrimmed);
    }

    /// @dev This method will supply the functionality for a Custom Operator rule, calling a method on another contract (like perform a calculation) via assembly
    function invokeCustomOperator(address targetContract, address, bytes32 methodName, bytes32 arg1, bytes32 arg2, bytes32 arg3, bytes32 arg4) public returns (string memory strAnswer) {

        bytes32 answer = methodName;

        // Since the Solidity compiler complains about the stack being too deep with local stack variables,
        // we must consolidate the code here to be one line
        bytes4 sig = bytes4(keccak256(abi.encodePacked(strConcat(bytes32ToString(methodName), "(bytes32,bytes32,bytes32,bytes32)"))));

        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)

            // append argument after function sig
            mstore(add(ptr,0x04), arg1)
            //Place second argument next to first, padded to 32 bytes
            mstore(add(ptr,0x24), arg2)
            //Place third argument next to second, padded to 64 bytes
            mstore(add(ptr,0x44), arg3)
            //Place fourth argument next to second, padded to 96 bytes
            mstore(add(ptr,0x64), arg4)

            let result := call(
                300000, // gas limit
                targetContract,
                0, // not transfer any ether
                ptr, // Inputs are stored at location ptr
                0x84, // Inputs are 132 bytes long
                ptr,  //Store output over input
                0x20) //Outputs are 32 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x84)) // Set storage pointer to new space
        }

        strAnswer = bytes32ToString(answer);
    }

    /// @dev This method allows the rules engine to call another contract's method via assembly, retrieving a value for evaluation
    /// @notice The target contract being called is expected to have a function 'methodName' with a specific signature
    function invokeValueRetrieval(address targetContract, address, bytes32 methodName, bytes32 attrName) public returns (string memory strAnswer) {

        string memory strMethodName = bytes32ToString(methodName);

        string memory functionNameAndParams = strConcat(strMethodName, "(bytes32)");

        bytes32 answer;

        bytes4 sig = bytes4(keccak256(abi.encodePacked(functionNameAndParams)));

        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), attrName)

            let result := call(
                15000, // gas limit
                targetContract,
                0, // not transfer any ether
                ptr, // Inputs are stored at location ptr
                0x24, // Inputs are 36 bytes long
                ptr,  //Store output over input
                0x20) //Outputs are 32 bytes long
            
            if eq(result, 0) {
                revert(0, 0)
            }
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x24)) // Set storage pointer to new space
        }

        strAnswer = bytes32ToString(answer);
    }

    /// @dev This method allows the rules engine to call another contract's method via assembly, for the purpose of assigning a value
    /// @notice The target contract being called is expected to have a function 'methodName' with a specific signature
    function invokeValueSetter(address targetContract, address, bytes32 methodName, bytes32 attrName, bytes32 value) public returns (string memory strAnswer) {

        string memory strMethodName = bytes32ToString(methodName);

        string memory functionNameAndParams = strConcat(strMethodName, "(bytes32,bytes32)");

        bytes32 answer = methodName;

        bytes4 sig = bytes4(keccak256(abi.encodePacked(functionNameAndParams)));        

        assembly {
            // move pointer to free memory spot
            let ptr := mload(0x40)
            // put function sig at memory spot
            mstore(ptr,sig)
            // append argument after function sig
            mstore(add(ptr,0x04), attrName)
            //Place second argument next to first, padded to 32 bytes
            mstore(add(ptr,0x24), value)

            let result := call(
                300000, // gas limit
                targetContract,
                0, // not transfer any ether
                ptr, // Inputs are stored at location ptr
                0x44, // Inputs are 56 bytes long
                ptr,  //Store output over input
                0x20) //Outputs are 32 bytes long

            if eq(result, 0) {
                revert(0, 0)
            }
            
            answer := mload(ptr) // Assign output to answer var
            mstore(0x40,add(ptr,0x44)) // Set storage pointer to new space
        }

        strAnswer = bytes32ToString(answer);
    }
    /// @notice Copied this code from Oraclize - // Copyright (c) 2015-2020 Oraclize
    /// @param _a The string to convert into an address
    /// @return The address converted from the string
    function parseAddr(string memory _a) internal pure returns (address) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    /// @notice Copied this code from Oraclize - // Copyright (c) 2015-2016 Oraclize srl, Thomas Bertani
    /// @dev This code definitely works
    /// @param _a The string to convert into an unsigned integer
    /// @param _b The number of decimal places that we wish to include in the unsigned integer, with 0 meaning none
    /// @return The unsigned integer converted from the string
    function parseInt(string memory _a, uint _b) public pure returns (uint) {
        
        uint bint = _b;
        uint mint = 0;

        bytes memory bresult = bytes(_a);
        bool decimals = false;

        for (uint i = 0; i < bresult.length; i++) {
            
            uint8 tmpNum = uint8(bresult[i]);
            
            if ((tmpNum >= 48) && (tmpNum <= 57)) {
                if (decimals) {
                    if (bint == 0) 
                        break;
                    else 
                        bint--;
                }
                mint *= 10;
                mint += tmpNum - 48;
                
            } else if (tmpNum == 46) 
                decimals = true;
        }

        return mint;
    }

    /// @dev This method will concatenate the provided strings into one larger string
    /// @notice 
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) public pure returns (string memory) {

        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        
        uint k = 0;
        
        for (uint a = 0; a < _ba.length; a++) {
            babcde[k++] = _ba[a];
        }

        for (uint b = 0; b < _bb.length; b++) {
            babcde[k++] = _bb[b];
        }

        for (uint c = 0; c < _bc.length; c++) {
            babcde[k++] = _bc[c];
        } 

        for (uint d = 0; d < _bd.length; d++) {
            babcde[k++] = _bd[d];
        }

        for (uint e = 0; e < _be.length; e++) { 
            babcde[k++] = _be[e];
        }

        return string(babcde);
    }

    /// @dev This method will concatenate the provided strings into one larger string
    /// @notice 
    function strConcat(string memory _a, string memory _b, string memory _c) public pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    /// @dev This method will concatenate the provided strings into one larger string
    /// @notice 
    function strConcat(string memory _a, string memory _b) public pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    /// @dev This method will convert a 'string' type to a 'bytes32' type
    /// @notice 
    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
        
    }

    /// @notice Copied this code from MIT implentation
    /// @dev This method will convert a 'uint' type to a 'bytes32' type
    function uintToBytes(uint targetVal) public pure returns (bytes32 ret) {

        uint v = targetVal;

        if (v == 0) {
            ret = "0";
        }
        else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }

        return ret;
    }

}