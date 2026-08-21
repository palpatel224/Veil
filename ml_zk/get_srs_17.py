import ezkl
import asyncio

async def main():
    await ezkl.get_srs(srs_path="kzg.srs", logrows=17)
    print("Fetched SRS for 17")

if __name__ == "__main__":
    asyncio.run(main())
