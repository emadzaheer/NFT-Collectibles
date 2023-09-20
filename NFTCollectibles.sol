// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Carta is ERC721, ERC721URIStorage, Pausable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;

    event addressAdded(address _address, bool _isUser, bool _isPartner );

    Counters.Counter private _tokenIdCounter;

    mapping (address => S_addressInfo ) m_users;
    mapping(address => EnumerableSet.UintSet) private ownedNFTs;

    struct S_addressInfo{
        bool isUser;
        bool isPartner;
        uint256[] receivedCollectibles;
        uint256[] sentCollectibles;
        uint256[] mintedCollectibles;
    }

    function addUser( address _user) external onlyOwner{
        require(!m_users[_user].isUser, "user already registered"); 
        m_users[_user].isUser = true;
        emit addressAdded(_user, true, m_users[_user].isPartner );
    }

    function addPartner(address _partner ) external onlyOwner{
        require(!m_users[_partner].isPartner, "partner already registered"); 
        m_users[_partner].isPartner = true;
        emit addressAdded(_partner, m_users[_partner].isUser, true );
    }

    constructor() ERC721("Carta", "CRTA") {}

    function _baseURI() internal pure override returns (string memory) {
        return "www.URIs.com/";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
    
    function safeMint(address _to, string memory _uri) public onlyOwner {      
        require(m_users[_to].isPartner, "destination address is not a partner");
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        ownedNFTs[_to].add(tokenId);
        m_users[_to].mintedCollectibles.push(tokenId);
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, _uri);
    }

    function batchMint(address _to, string[] memory _uris) external onlyOwner{
        uint256 length = _uris.length;
        require(length < 251, "Max limit = 250");
        require(m_users[_to].isPartner, "only partner can mint" );

        for (uint i; i<length; ++i){
            safeMint(_to, _uris[i]);
        }
    } 

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override
    {   
        //minting is done from address 0 so .....
        if(from != address(0)) {
            ownedNFTs[from].remove(tokenId);
            ownedNFTs[to].add(tokenId);
            m_users[from].sentCollectibles.push(tokenId);
            m_users[to].receivedCollectibles.push(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    // Getter functions

    function getAddressDetails (address _address ) public view returns(S_addressInfo memory ) {
        return m_users[_address];
    }

    function getOwnedNFTs(address user) public view returns (uint256[] memory) {
        uint256[] memory nfts = new uint256[](getNFTCount(user));
        for (uint256 i = 0; i < getNFTCount(user); i++) {
            nfts[i] = getNFTAtIndex(user, i);
        }
        return nfts;
    }
    
     // Get the count of NFTs owned by a user
    function getNFTCount(address user) public view returns (uint256) {
        return ownedNFTs[user].length();
    }

    // Get the NFT at a specific index in a user's collection
    function getNFTAtIndex(address user, uint256 index) private view returns (uint256) {
        require(index < getNFTCount(user), "Index out of bounds");
        return ownedNFTs[user].at(index);
    }
    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal onlyOwner override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
