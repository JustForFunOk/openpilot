#!/usr/bin/env python3
import carla  # pylint: disable=import-error

if __name__ == "__main__":
  client = carla.Client("127.0.0.1", 2000)
  client.set_timeout(10.0)
  print(client.get_available_maps())