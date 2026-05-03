# APP Homepage A/B Test Analysis

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue)](https://python.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0%2B-orange)](https://mysql.com)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

End-to-end A/B test analysis for an APP homepage UI redesign. Features rigorous statistical methodology: SRM check, multiple testing correction (BH-FDR), effect size estimation, and power analysis.

---

## Experiment Overview

| Item | Detail |
|------|--------|
| Hypothesis | New homepage (repositioned banner + larger cards) improves engagement |
| Control | Old homepage layout (Group A) |
| Treatment | New homepage layout (Group B) |
| Duration | 14 days |
| Sample size | 5,000 users (50/50 random split) |
| Primary metric | CTR (Click-through rate) |

---

## Key Results

| Metric | Control | Treatment | Lift | Significant (BH) |
|--------|---------|-----------|------|-------------------|
| CTR | 38.0% | 48.0% | **+26.3%** | ✓ |
| Feature enter rate | 43.0% | 52.0% | **+20.9%** | ✓ |
| 7-day retention | 46.0% | 55.0% | **+19.6%** | ✓ |
| Avg session duration | 240s | 320s | **+33.3s** | ✓ |
| Share rate | 14.0% | 18.0% | **+28.6%** | ✓ |

**Recommendation: Full rollout of new homepage design.**

---

## Statistical Methodology

- **Power analysis**: Minimum sample size calculation (MDE=3%, α=0.05, Power=80%)
- **SRM check**: χ² test to verify traffic split uniformity before analysis
- **Hypothesis testing**: Two-sided z-test (proportions); two-sample t-test (continuous)
- **Multiple testing correction**: Benjamini-Hochberg FDR across 6 metrics
- **Effect size**: Cohen's h (proportions), Cohen's d (continuous)
- **Confidence intervals**: 95% CI for all metric differences

---

## Repository Structure

```
app-ab-test/
├── README.md
├── requirements.txt
├── sql/
│   ├── schema.sql          # DB + table creation + stored procedure (5000 users)
│   └── analysis.sql        # CTR, retention, funnel, DAU trend queries
├── src/
│   └── ab_test_analysis.py # Full statistical analysis + 6-panel visualization
└── results/
    └── ab_test_report.png  # Output report
```

---

## Quick Start

```bash
git clone https://github.com/magcianbbll-droid/app-ab-test.git
cd app-ab-test
pip install -r requirements.txt

# Run in offline mode (no MySQL needed — uses built-in simulated data)
python src/ab_test_analysis.py
```

### MySQL setup (optional)
```bash
mysql -u root -p < sql/schema.sql    # Create DB, tables, generate data (~1 min)
mysql -u root -p ab_test_app < sql/analysis.sql  # Run analysis queries
```

---

## References

1. Kohavi, R., Tang, D., & Xu, Y. (2020). *Trustworthy Online Controlled Experiments*. Cambridge University Press.
2. Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate. *JRSS-B*, 57(1), 289–300.

---

## License

MIT License
