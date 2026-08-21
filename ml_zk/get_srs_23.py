import ezkl
import asyncio

async def main():
    await ezkl.get_srs(logrows=8, srs_path="kzg.srs")
    print("Downloaded kzg.srs for logrows=8")

if __name__ == "__main__":
    asyncio.run(main())
