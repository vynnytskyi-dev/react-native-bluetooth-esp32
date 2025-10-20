import { TurboModule, TurboModuleRegistry } from "react-native";

export interface Spec extends TurboModule {
  startScan(serviceUUID: string, charUUID: string): void;
  stop(): void;
}

export default TurboModuleRegistry.getEnforcing<Spec>("StepBleManager");
