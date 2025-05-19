import asyncio
import requests
import json
from bs4 import BeautifulSoup
from crawl4ai.docker_client import Crawl4aiDockerClient
from crawl4ai import BrowserConfig, CrawlerRunConfig, CacheMode # Assuming you have crawl4ai installed
from crawl4ai.extraction_strategy import JsonCssExtractionStrategy
import os
from dotenv import load_dotenv
load_dotenv()

# if running without docker
# URL = "http://127.0.0.1:8123"

# if running in docker, use the container name as the hostname
# this uses the shared 'rsm-docker' network to connect
# URL = "http://rsm-msba-k8s-latest:8123"

URL = "https://rsm-shiny-02.ucsd.edu/selenium/"
URL_AUTH = "https://rsm-shiny-02.ucsd.edu/selenium_auth/"

def test_bs4():
    # This function is not used in the code, but it seems to be a placeholder for testing
    # BeautifulSoup functionality
    response = requests.get(URL)
    soup = BeautifulSoup(response.content, "html.parser")
    print("Title found by BeautifulSoup:", soup.find("title").text if soup.find("title") else "No title found")
    print("Button found by BeautifulSoup:", bool(soup.find("button", id="showText")))
    print("Dynamic text element found by BeautifulSoup:", bool(soup.find(id="dynamicText")))
    print("Dynamic text found by BeautifulSoup:", soup.find(id="dynamicText").text)


async def test_docker():
    # must run from docker container
    async with Crawl4aiDockerClient(base_url="http://rsm-crawl0:11235", verbose=True, verify_ssl=False) as client:
        await client.authenticate(email="vnijs@ucsd.edu")  # Authenticate before crawling
        results = await client.crawl(
            [URL],
            browser_config=BrowserConfig(
                headless=True
            ),  # Use library classes for config aid
            crawler_config=CrawlerRunConfig(cache_mode=CacheMode.BYPASS),
        )
        if results:  # client.crawl returns None on failure
            print(f"Non-streaming results success: {results.success}")
            if results.success:
                print(f"HTML: {results.cleaned_html}")
                print(f"Markdown: {results.markdown}")

async def test_ids():
    # must run from docker container
    schema = {
        "name": "ElementCheck",
        "baseSelector": "body",
        "fields": [
            {"name": "showText_value", "selector": "button#showText", "type": "text"},
            {"name": "dynamicText_value", "selector": "#dynamicText", "type": "text"}
        ]
    }
    crawler_config = CrawlerRunConfig(
        cache_mode=CacheMode.BYPASS,
        extraction_strategy=JsonCssExtractionStrategy(schema)
    )
    async with Crawl4aiDockerClient(base_url="http://rsm-crawl0:11235", verbose=True, verify_ssl=False) as client:
        await client.authenticate(email="vnijs@ucsd.edu")
        # First crawl: before clicking
        results = await client.crawl(
            [URL],
            browser_config=BrowserConfig(headless=True),
            crawler_config=crawler_config,
        )
        if results and results.success:
            data = json.loads(results.extracted_content)
            print("Button showText exists:", data[0]["showText_value"] != "")
            print("Dynamic text visible (before click):", data[0]["dynamicText_value"] != "")
        # Second crawl: click the button and check again
        js_click_and_wait = """
        document.getElementById('showText').click();
        await new Promise(r => setTimeout(r, 500));
        """
        crawler_config_click = CrawlerRunConfig(
            cache_mode=CacheMode.BYPASS,
            extraction_strategy=JsonCssExtractionStrategy(schema),
            js_code=[js_click_and_wait],
            capture_console_messages=True,
        )
        results_click = await client.crawl(
            [URL],
            browser_config=BrowserConfig(headless=True, java_script_enabled=True),
            crawler_config=crawler_config_click,
        )
        if results_click and results_click.success:
            data_click = json.loads(results_click.extracted_content)
            print("Dynamic text visible (after click):", data_click[0]["dynamicText_value"] != "")
            print("Dynamic text value (after click):", data_click[0]["dynamicText_value"])


if __name__ == "__main__":
    print("=== BeautifulSoup test ===")
    test_bs4()
    print("=== Crawl4ai basic test ===")
    asyncio.run(test_docker())
    print("=== Crawl4ai checking ids ===")
    asyncio.run(test_ids())
    # print("=== Crawl4ai checking authentication ===")
    # asyncio.run(test_authentication())

