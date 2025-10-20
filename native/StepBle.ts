import { NativeEventEmitter, NativeModules } from "react-native";

const native = NativeModules.StepBleManager;
const emitter = native ? new NativeEventEmitter(native) : null;

export function start(serviceUUID: string, charUUID: string) {
  native?.startScan?.(serviceUUID, charUUID);
}
export function stop() {
  native?.stop?.();
}
export function onStep(cb: (n: number) => void) {
  if (!emitter) return () => {};
  const sub = emitter.addListener("StepBleOnStep", (e: { value: string }) => {
    const n = parseInt((e?.value || "0").trim(), 10);
    if (!isNaN(n)) cb(n);
  });
  return () => sub.remove();
}
export function onLog(cb: (msg: string) => void) {
  if (!emitter) return () => {};
  const sub = emitter.addListener("StepBleLog", cb);
  return () => sub.remove();
}
