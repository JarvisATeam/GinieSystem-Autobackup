export function computeConfidence(args: {
  customerConfidence: number;
  jobSummaryLength: number;
  deliverablesCount: number;
}): number {
  const lenScore = args.jobSummaryLength > 300 ? 0.9 : args.jobSummaryLength > 150 ? 0.6 : 0.3;
  const delScore = args.deliverablesCount > 2 ? 0.9 : args.deliverablesCount > 0 ? 0.6 : 0.3;
  return Math.min(args.customerConfidence, lenScore, delScore);
}
