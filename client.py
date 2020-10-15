import asyncio
import websockets
import json
import socket

async def hello():
    uri = "ws://localhost:9000"
    async with websockets.connect(uri) as websocket:
        print("opening")
        with open("file.json", 'r') as f:
            data = f.read()

        await websocket.send(data)
        #print(f"{data}")
        print("sent")
        greeting = await websocket.recv()
        print(f"< {greeting}")

# asyncio.get_event_loop().run_until_complete(hello())

soc = socket.socket()
soc.connect(("localhost", 9000))
# soc.listen(1)
# # with open("file.json", 'rb') as f:
# #     data = f.read()
# with soc:
#     con, addr = soc.accept()
#     with con:
#         data = b'test'
#         con.sendall(data)
#         print("file sent")

# with open("recv.json", 'wb') as f:

#     while True:
#         new_data = soc.send(4096)
#         if not new_data:
#             break
#         f.write(new_data)
# print("file recv")
soc.send(b'test')