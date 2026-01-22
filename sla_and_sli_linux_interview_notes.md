# SLA and SLI in Linux – Interview Ready Notes

This document explains **SLI (Service Level Indicator)** and **SLA (Service Level Agreement)** in a **Linux / DevOps context**, with clear definitions, examples, and interview-ready explanations.

---

## 1. What is SLI (Service Level Indicator)?

**SLI** is a **measurable metric** used to understand **how well a system or service is performing**.

👉 Think of **SLI as what we measure**.

### Common SLIs in Linux environments
- CPU usage
- Memory usage
- Disk usage
- Network latency
- Service uptime
- Error rate (4xx / 5xx)

These metrics are collected from **Linux systems** using tools such as:
- `top`, `htop`
- `vmstat`, `iostat`, `sar`
- `uptime`
- Application and system logs (`/var/log`)

### Example SLI
```text
CPU usage = 75%
Service uptime = 99.95%
Error rate = 0.02%
```

📌 These measured values are **SLIs**.

---

## 2. What is SLA (Service Level Agreement)?

**SLA** is a **formal agreement** between a **service provider** and a **customer**.

It defines:
- Guaranteed service level (availability, performance)
- Measurement period (monthly / yearly)
- Penalties or service credits if the guarantee is not met

👉 Think of **SLA as what is promised**.

### Example SLA
```text
The service will provide 99.9% availability per month.
If availability drops below 99.9%, the customer is eligible for service credits.
```

📌 SLA is **business / legal**, not a Linux feature.

---

## 3. Relationship Between SLI and SLA (Very Important)

| Term | Meaning |
|-----|--------|
| SLI | What is measured |
| SLA | What is promised |

👉 **SLIs are used to validate whether an SLA is met or violated**.

You **do not measure SLA directly**.
You **measure SLIs**, then compare them against the SLA.

---

## 4. End-to-End Linux Example

### Scenario
You host a web application on a Linux server.

### SLA (Customer Agreement)
```text
Application availability must be 99.9% per month
```

### SLIs (Measured from Linux)
- Uptime from logs / monitoring
- CPU usage from `top`
- Error rate from application logs

### Example Measured SLIs
```text
Availability (SLI) = 99.5%
CPU usage = 82%
Error rate = 0.3%
```

### SLA Validation
```text
Required SLA availability = 99.9%
Actual availability (SLI) = 99.5%
```

❌ **SLA violated**

👉 Customer may raise a support case and request **service credits or penalties**, as defined in the SLA.

---

## 5. Cloud Provider Example (Interview Safe)

Cloud providers (like AWS, Azure, GCP) may experience **regional or service-specific outages**.

If actual **SLI values** (availability, latency) fall **below the SLA guarantee**, customers may be **eligible for service credits**, according to the SLA terms.

📌 Always say **“eligible for service credits”**, not guaranteed refunds.

---

## 6. Why SLA and SLI Matter in Linux / DevOps

Linux provides:
- Metrics
- Logs
- Performance data

These are used to:
- Monitor SLIs
- Detect SLA risks early
- Trigger alerts and automation
- Protect business commitments

Without SLIs:
- SLA cannot be validated
- No reliable monitoring
- Higher risk of outages

---

## 7. Common Interview Mistakes to Avoid

❌ Saying SLA is a Linux command
❌ Saying SLI is a monitoring tool
❌ Saying SLA is measured directly

✅ SLA is an agreement
✅ SLI is a metric
✅ Linux provides data for SLIs

---

## 8. Interview One-Liners (Must Remember)

**SLI**
> A Service Level Indicator is a measurable metric that reflects actual system or service performance.

**SLA**
> A Service Level Agreement is a formal commitment that defines guaranteed service levels and penalties if they are not met.

**Relationship**
> SLIs are used to validate whether an SLA has been met or violated.

---

## 9. Quick Memory Trick

- **SLI = Indicator (measurement)**
- **SLA = Agreement (promise)**

---

## 10. Final Summary

```text
Linux metrics → SLI → Compare with SLA → Alerts / Credits / Action
```

This flow is used in **real production systems**, **cloud platforms**, and **DevOps environments**.

---

✅ Use this document as a **ready reference for interviews and real-world discussions**.

