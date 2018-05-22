pragma solidity ^0.4.18;

///Author Dieter Shirley (https://github.com/dete)
contract ERC721 {

    event LogTransfer(address from, address to, uint256 tokenId);
    event LogApproval(address owner, address approved, uint256 tokenId);

    function name() public view returns (string);
    function symbol() public view returns (string);
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);

}
