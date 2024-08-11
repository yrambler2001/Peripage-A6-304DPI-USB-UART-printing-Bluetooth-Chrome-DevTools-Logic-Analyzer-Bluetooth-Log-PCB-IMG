
import asyncio
from bleak import BleakClient

address = "BBFBF730-B709-110E-3BDE-02B32111C2D0"
# MODEL_NBR_UUID = "FF03"
MODEL_NBR_UUID = "2800"



def chunks(lst, n):
    """Yield successive n-sized chunks from lst."""
    for i in range(0, len(lst), n):
        yield lst[i:i + n]

async def main(address):
    client = BleakClient(address)
    try:
        await client.connect()
        # print(await client.services())
        await client.write_gatt_char("49535343-8841-43F4-A8D4-ECBE34729BB3",bytes.fromhex("02"))
        # await client.write_gatt_char(0x000f,bytes.fromhex("02"))
        # await client.write_gatt_char(0x10,bytes.fromhex("01"))
        # await client.read_gatt_char("2803")

        # await client.write_gatt_char(9,bytes.fromhex("0200"))
        # await client.write_gatt_char(10,bytes.fromhex("0100"))
        # await client.write_gatt_char(15,bytes.fromhex("0100"))
        ff=False
        async def CB(e,ee):
          print(e," a ",ee)
          if(ff):
            await client.write_gatt_char("FF02",bytes.fromhex("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),response=False)
            await client.write_gatt_char("FF02",bytes.fromhex("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),response=False)

        r1 = await client.start_notify("FF01",CB)
        r2 = await client.start_notify("FF03",CB)
        r3 = await client.start_notify("49535343-1E4D-4BD9-BA61-23C647249616",CB)
        # r1 = await client.start_notify(0x000f,CB)
        print(1)
        # # print(r1)
        # r2 = await client.start_notify("FF01",CB)
        # await client.write_gatt_char("",bytes.fromhex("10ffff8d"))
        await client.write_gatt_char("FF02",bytes.fromhex("10ffff8d"))
        print(2)
        await client.write_gatt_char("FF02",bytes.fromhex("10ff70"))
        print(3)
        await client.write_gatt_char("FF02",bytes.fromhex("10ff20f0"))
        print(4)
        await client.write_gatt_char("FF02",bytes.fromhex("10ff3010"))
        print(5)
        await client.write_gatt_char("FF02",bytes.fromhex("10ff100000"))
        print(6)
        await client.write_gatt_char("FF02",bytes.fromhex("10fffe01"))
        print(7)
        await asyncio.sleep(2)
        ff=True
        await client.write_gatt_char("FF02",bytes.fromhex("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),response=False)
        await client.write_gatt_char("FF02",bytes.fromhex("00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"),response=False)

        

        # for iter in range(0, 10):
        #   await client.write_gatt_char("FF02",bytes.fromhex("0"*100),response=True)
        #   await client.write_gatt_char("FF02",bytes.fromhex("0"*100),response=True)


        # string_val = "x" * 10
        # print(r2)
        # print("Model Number: {0}".format("".join(map(chr, model_number))))
        await asyncio.sleep(10)

    except Exception as e:
        print(e)
    finally:
        await client.disconnect()

asyncio.run(main(address))