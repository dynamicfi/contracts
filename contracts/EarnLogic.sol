// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            

 */

contract EarnLogic is Ownable {
    // structs and events
    struct EIP712Signature {
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event ClaimToken(address claimer, uint256 amount);

    // variables and mappings
    IERC20 public token;
    address public provider;
    address public signer;
    bytes32 CLAIM_TOKEN_WITH_SIG_TYPEHASH =
        keccak256(
            "claimTokenWithSig(uint256 amount,uint256 nonce,uint256 deadline)"
        );

    mapping(address => uint256) public claimTokenSigNonces;

    // constructor and functions
    constructor(
        address _tokenAddress,
        address _provider,
        address _signer
    ) {
        token = IERC20(_tokenAddress);
        provider = _provider;
        signer = _signer;
    }

    function changeTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function changeProvider(address _provider) external onlyOwner {
        provider = _provider;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function claimTokenWithSig(uint256 _amount, EIP712Signature memory _sig)
        external
    {
        require(
            _sig.deadline == 0 || _sig.deadline >= block.timestamp,
            "Signature expired"
        );

        bytes32 domainSeparator = _calculateDomainSeparator();

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        CLAIM_TOKEN_WITH_SIG_TYPEHASH,
                        _amount,
                        claimTokenSigNonces[msg.sender]++,
                        _sig.deadline
                    )
                )
            )
        );

        address recoveredAddress = ecrecover(digest, _sig.v, _sig.r, _sig.s);
        require(recoveredAddress == signer, "Dyna: invalid signature");

        //handle logic of claim token
        token.transferFrom(provider, _msgSender(), _amount);

        emit ClaimToken(msg.sender, _amount);
    }

    // internal functions
    function _calculateDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,address verifyingContract)"
                    ),
                    keccak256(bytes("Dyna")),
                    keccak256(bytes("1")),
                    address(this)
                )
            );
    }
}
