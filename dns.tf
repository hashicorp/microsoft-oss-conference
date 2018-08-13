resource "dnsimple_record" "foobar" {
  domain = "demo.gs"
  name   = "web.gopher"
  value  = "${kubernetes_service.gophersearch.load_balancer_ingress.0.ip}"
  type   = "A"
  ttl    = 360
}
