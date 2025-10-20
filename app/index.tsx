import { useEffect, useState } from "react";
import { Button, StyleSheet, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import * as StepBle from "../native/StepBle";

const SERVICE = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHAR = "beefcafe-36e1-4688-b7f5-00000000000b";

export default function App() {
  const [steps, setSteps] = useState<number>(0);
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    const offStep = StepBle.onStep((n) => setSteps(n));
    const offLog = StepBle.onLog((msg) =>
      setLogs((l) => [msg, ...l].slice(0, 10))
    );
    return () => {
      offStep();
      offLog();
      StepBle.stop();
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Steps</Text>
      <Text style={styles.steps}>{steps}</Text>
      <View style={styles.buttons}>
        <Button
          title="Start BLE"
          onPress={() => StepBle.start(SERVICE, CHAR)}
        />
        <Button title="Stop" onPress={() => StepBle.stop()} />
      </View>

      <View style={styles.logsContainer}>
        <Text style={styles.logsTitle}>Logs (last 10):</Text>
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
