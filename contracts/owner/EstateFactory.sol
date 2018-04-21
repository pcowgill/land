pragma solidity ^0.4.23;

import './EstateOwner';
import './IEstateFactory';

contract EstateFactory is IEstateFactory {

    function buildEstate(address dar, address beneficiary) external returns (address) {
        EstateOwner estate = new EstateOwner(
            dar,
            beneficiary
        );
        return address(estate);
    }

}
