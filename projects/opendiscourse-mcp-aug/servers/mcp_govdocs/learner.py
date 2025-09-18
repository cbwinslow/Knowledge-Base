import httpx, re, urllib.parse, xml.etree.ElementTree as ET
from typing import List, Dict

async def fetch_text(url: str, timeout: float = 15.0) -> str | None:
    try:
        async with httpx.AsyncClient(follow_redirects=True, timeout=timeout) as client:
            r = await client.get(url, headers={"User-Agent": "OpenDiscourseGovDocs/0.1"})
            if r.status_code == 200 and r.text:
                return r.text
    except Exception:
        return None
    return None

async def discover_sitemaps(domain: str) -> List[str]:
    base = f"https://{domain}"
    robots = await fetch_text(f"{base}/robots.txt")
    sitemaps: List[str] = []
    if robots:
        for line in robots.splitlines():
            if line.lower().startswith("sitemap:"):
                sm = line.split(":", 1)[1].strip()
                sitemaps.append(sm)
    if not sitemaps:
        # try common locations
        for p in ["/sitemap.xml", "/sitemap_index.xml"]:
            sitemaps.append(f"{base}{p}")
    # de-dup & normalize
    seen = set()
    out = []
    for u in sitemaps:
        nu = urllib.parse.urljoin(base + "/", u.strip())
        if nu not in seen:
            seen.add(nu); out.append(nu)
    return out

def parse_sitemap(xml_text: str) -> List[str]:
    urls: List[str] = []
    try:
        root = ET.fromstring(xml_text)
        ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        # sitemapindex
        for loc in root.findall(".//sm:sitemap/sm:loc", ns):
            urls.append(loc.text.strip())
        # urlset
        for loc in root.findall(".//sm:url/sm:loc", ns):
            urls.append(loc.text.strip())
    except Exception:
        pass
    return urls[:5000]  # cap
