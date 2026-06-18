source ${z_main}

z.t.describe "wtproxy constants"; {
  z.t.context "default config values"; {
    z.t.it "default proxy portsを持つ"; {
      z.t.expect "$z_wtproxy_default_config_values[proxy_port_1]" 3000
      z.t.expect "$z_wtproxy_default_config_values[proxy_port_2]" 5432
      z.t.expect "$z_wtproxy_default_config_values[proxy_port_3]" 5173
    }
  }
}
