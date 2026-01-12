import { Socket } from "phoenix";

const socket = new Socket("ws://localhost:4000/socket", {
  params: { token: window["userToken"] },
});

socket.connect();

export const channel = socket.channel("agents:lobby", {});

channel
  .join()
  .receive("ok", (resp) => {
    console.log("Joined successfully", resp);
  })
  .receive("error", (resp) => {
    console.log("Unable to join", resp);
  });

export default socket;

