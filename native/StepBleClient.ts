import { NativeEventEmitter, NativeModules } from "react-native";
import StepBle from "./specs/NativeStepBle"; // TurboModule instance

const emitter = new NativeEventEmitter(NativeModules.StepBleManager);

export function start(service: string, charUUID: string) {
  StepBle.startScan(service, charUUID);
}
export function stop() {
  StepBle.stop();
}
export function onStep(cb: (n: number) => void) {
  const sub = emitter.addListener("StepBleOnStep", (e: { value: string }) => {
    const n = parseInt((e?.value || "").trim(), 10);
    if (!isNaN(n)) cb(n);
  });
  return () => sub.remove();
}
export function onLog(cb: (msg: string) => void) {
  const sub = emitter.addListener("StepBleLog", cb);
  return () => sub.remove();
}
