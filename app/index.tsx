import { useEffect, useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";
import { onLog, onStep, start, stop } from "../native/StepBleClient";

const SERVICE = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHAR = "beefcafe-36e1-4688-b7f5-00000000000b";

export default function Home() {
  const [steps, setSteps] = useState(0);
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    const off1 = onStep((n) => setSteps(n));
    const off2 = onLog((m) => setLogs((l) => [m, ...l].slice(0, 5)));
    return () => {
      off1();
      off2();
      stop();
    };
  }, []);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.body}>
        <Text style={styles.title}>STEPS</Text>
        <View style={styles.stepsContainer}>
          <Text style={styles.steps}>{steps}</Text>
        </View>
        <View style={styles.buttons}>
          <TouchableOpacity
            style={styles.button}
            onPress={() => {
              start(SERVICE, CHAR);
            }}
          >
            <Text style={styles.buttonText}>START</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.button}
            onPress={() => {
              stop();
            }}
          >
            <Text style={styles.buttonText}>STOP</Text>
          </TouchableOpacity>
        </View>
      </View>
      <View style={styles.logsContainer}>
        {logs.length > 0 && (
          <>
            <Text style={styles.logsTitle}>Logs:</Text>
            {logs.map((l, i) => (
              <Text key={i} style={styles.logs}>
                {l}
              </Text>
            ))}
          </>
        )}
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
  body: {
    flex: 5,
    justifyContent: "center",
    alignItems: "center",
  },
  title: {
    fontSize: 72,
    fontWeight: "bold",
  },
  stepsContainer: {
    width: 180,
    height: 180,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 10,
    borderColor: "red",
    borderRadius: 100,
    marginVertical: 24,
  },
  steps: {
    fontSize: 72,
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
    flex: 2,
    marginTop: 24,
    width: "100%",
  },
  button: {
    width: 100,
    paddingVertical: 10,
    borderRadius: 10,
    backgroundColor: "black",
    alignItems: "center",
    justifyContent: "center",
    marginTop: 10,
    marginHorizontal: 10,
  },
  buttonText: {
    color: "white",
    fontWeight: "bold",
  },
});
