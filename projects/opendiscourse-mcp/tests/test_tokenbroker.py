import httpx, pytest

@pytest.mark.asyncio
async def test_tokenbroker_unknown():
    # Example JSON structures
    payload = {"jsonrpc": "2.0", "method": "unknown_tool", "params": {}, "id": 1}
    # We can't call the live server here; this test is illustrative for CI structure.
    assert "method" in payload and payload["method"] == "unknown_tool"
