import { useEffect, useState } from "react";
import { Button, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { onLog, onStep, start, stop } from "../native/StepBleClient";

const SERVICE = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHAR = "beefcafe-36e1-4688-b7f5-00000000000b";

export default function Home() {
  const [steps, setSteps] = useState(0);
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    const off1 = onStep((n) => setSteps(n));
    const off2 = onLog((m) => setLogs((l) => [m, ...l].slice(0, 8)));
    return () => {
      off1();
      off2();
      stop();
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Steps</Text>
      <Text style={styles.steps}>{steps}</Text>
      <View style={styles.buttons}>
        <Button title="Start BLE" onPress={() => start(SERVICE, CHAR)} />
        <Button title="Stop" onPress={() => stop()} />
      </View>
      <View style={styles.logsContainer}>
        <Text style={styles.logsTitle}>Logs:</Text>
        {logs.map((l, i) => (
          <Text key={i} style={styles.logs}>
            {l}
          </Text>
        ))}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    gap: 16,
    justifyContent: "center",
    alignItems: "center",
  },
  title: {
    fontSize: 42,
    fontWeight: "400",
  },
  steps: {
    fontSize: 92,
    fontWeight: "bold",
  },
  buttons: {
    flexDirection: "row",
  },
  logs: {
    fontSize: 12,
  },
  logsTitle: {
    fontWeight: "600",
  },
  logsContainer: {
    marginTop: 24,
    width: "100%",
  },
});
