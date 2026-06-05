package main

import "log"

type transferRateEstimate struct {
	label       string
	bytesPerSec float64
}

// Conservative effective throughput for planning (not wire speed).
var commonTransferRates = []transferRateEstimate{
	{label: "100 Mb/s WAN", bytesPerSec: 12.5 * 1024 * 1024},
	{label: "1 GbE", bytesPerSec: 110 * 1024 * 1024},
	{label: "10 GbE", bytesPerSec: 1.1 * 1024 * 1024 * 1024},
	{label: "25 GbE", bytesPerSec: 2.8 * 1024 * 1024 * 1024},
}

func diffRecordTransfersBytes(reason string, size int64) bool {
	if reason == "missing_on_source" {
		return false
	}
	return size > 0
}

func logRepairTransferEstimate(blocks uint64, bytes int64) {
	if blocks == 0 || bytes == 0 {
		log.Printf("repair transfer: nothing to copy from source (apply skips missing_on_source)")
		return
	}
	log.Printf("repair transfer: %d blocks, %s to read from source and write to dest", blocks, formatBytes(bytes))
	log.Printf("estimated apply duration (serial read+write; parallel workers may be faster):")
	for _, rate := range commonTransferRates {
		eta := formatETA(0, bytes, rate.bytesPerSec)
		throughput := formatBytes(int64(rate.bytesPerSec))
		log.Printf("  @ %s (~%s/s): %s", rate.label, throughput, eta)
	}
}
