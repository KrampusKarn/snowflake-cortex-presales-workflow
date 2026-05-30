import os
import sys
import json
import argparse
import asyncio
from typing import Optional

# This script is used by the generating-brand-guidelines skill to analyze a website's visual style.
# It requires Playwright to be installed in the environment.

async def analyze_website(url: str, output_dir: str):
    try:
        from playwright.async_api import async_playwright
    except ImportError:
        print("Error: playwright not installed. Please install it with 'pip install playwright' and 'playwright install chromium'")
        return

    async with async_playwright() as p:
        print(f"Opening browser to {url}...")
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Set a standard viewport
        await page.set_viewport_size({"width": 1440, "height": 900})
        
        await page.goto(url, wait_until="networkidle")
        
        # 1. Take Screenshot
        screenshot_path = os.path.join(output_dir, "website_screenshot.png")
        await page.screenshot(path=screenshot_path, full_page=False)
        print(f"Screenshot saved to {screenshot_path}")

        # 2. Extract Computed Styles
        # We'll look at the body and some common elements to guess the brand tokens.
        analysis = await page.evaluate("""
            () => {
                const getStyle = (el, prop) => window.getComputedStyle(el).getPropertyValue(prop);
                
                const body = document.body;
                const h1 = document.querySelector('h1') || body;
                const button = document.querySelector('button') || document.querySelector('a.btn') || body;

                return {
                    typography: {
                        body_font: getStyle(body, 'font-family'),
                        heading_font: getStyle(h1, 'font-family'),
                        base_font_size: getStyle(body, 'font-size')
                    },
                    colors: {
                        background: getStyle(body, 'background-color'),
                        text: getStyle(body, 'color'),
                        heading: getStyle(h1, 'color'),
                        accent: getStyle(button, 'background-color') || getStyle(button, 'color')
                    },
                    spacing: {
                        body_padding: getStyle(body, 'padding'),
                        body_margin: getStyle(body, 'margin')
                    }
                };
            }
        """)

        # 3. Save Analysis Data
        json_path = os.path.join(output_dir, "analysis_data.json")
        with open(json_path, 'w') as f:
            json.dump(analysis, f, indent=4)
        print(f"Analysis data saved to {json_path}")

        await browser.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze a website's brand tokens.")
    parser.add_argument("--url", required=True, help="URL of the website to analyze")
    parser.add_argument("--out", default="./Input/brand_references/", help="Output directory")

    args = parser.parse_args()

    if not os.path.exists(args.out):
        os.makedirs(args.out)

    asyncio.run(analyze_website(args.url, args.out))
