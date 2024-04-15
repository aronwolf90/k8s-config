variables {
  hcloud_token = "123456789_123456789_123456789_123456789_123456789_123456789_1234"
}

run "default_config" {
  command = plan

  assert {
    condition     = output.host == null
    error_message = "Default config is not working"
  }
}
