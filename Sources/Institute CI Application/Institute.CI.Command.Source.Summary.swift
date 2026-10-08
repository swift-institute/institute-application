public import Institute_CI_Model
public import Institute_Model
public import Source_Report

extension Institute.CI.Command.Source {
    /// A bounded, human-readable account of a source report for standard
    /// error. The JSON report on standard output stays the record; this names
    /// the outcome, every reason a report is unmeasured, and the findings by
    /// location, rule and message, up to `limit`.
    public static func summary(
        _ report: Source_Report.Source.Report,
        exitCode: Swift.Int32,
        limit: Swift.Int = 50
    ) -> [Swift.String] {
        var lines: [Swift.String] = []
        switch Source_Report.Source.Report.Status(report, expected: report.commitment) {
        case .clean:
            lines.append("institute ci source: clean (exit \(exitCode))")
        case .findings:
            lines.append("institute ci source: findings (exit \(exitCode))")
        case .unmeasured:
            lines.append("institute ci source: UNMEASURED, the report is incomplete (exit \(exitCode))")
            do throws(Source_Report.Source.Report.Complete.Error) {
                _ = try Source_Report.Source.Report.Complete(report, expected: report.commitment)
            } catch {
                lines.append("unmeasured: incomplete report: \(error)")
            }
            for measurement in report.measurements {
                guard case .unmeasured(let reasons) = measurement.verdict else { continue }
                for reason in reasons {
                    lines.append("unmeasured: \(measurement.engine.token): \(reason.code): \(reason.detail)")
                }
            }
            for evidence in report.artifactEvidence {
                guard case .unmeasured(let reasons) = evidence.verdict else { continue }
                for reason in reasons {
                    lines.append("unmeasured: \(evidence.artifact.path): \(reason.code): \(reason.detail)")
                }
            }
            for evidence in report.controlEvidence {
                guard case .unmeasured(let reasons) = evidence.verdict else { continue }
                for reason in reasons {
                    lines.append("unmeasured: control \(evidence.identity): \(reason.code): \(reason.detail)")
                }
            }
        }

        var findings: [Swift.String] = []
        for measurement in report.measurements {
            guard case .findings(let found) = measurement.verdict else { continue }
            for finding in found {
                let diagnostic = finding.diagnostic
                let location = diagnostic.location
                findings.append(
                    "\(location.filePath ?? location.fileID):\(location.line):\(location.column): "
                        + "\(diagnostic.severity): [\(measurement.engine.token) \(finding.rule.token)] "
                        + diagnostic.message
                )
            }
        }
        for evidence in report.artifactEvidence {
            guard case .findings(let reasons) = evidence.verdict else { continue }
            for reason in reasons {
                findings.append(
                    "\(evidence.artifact.path): [\(evidence.predicate.token)] \(reason.code): \(reason.detail)"
                )
            }
        }
        for evidence in report.controlEvidence {
            guard case .findings(let reasons) = evidence.verdict else { continue }
            for reason in reasons {
                findings.append("control \(evidence.identity): \(reason.code): \(reason.detail)")
            }
        }

        lines.append(contentsOf: findings.prefix(limit))
        if findings.count > limit {
            lines.append(
                "\(findings.count - limit) more findings omitted; the JSON report on standard output has all \(findings.count)"
            )
        }
        return lines
    }
}
