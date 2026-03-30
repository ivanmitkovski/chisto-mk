"use client";

import { motion } from "framer-motion";
import { Star } from "lucide-react";

interface FeatureCardProps {
  title: string;
  description: string;
}

export function FeatureCard({ title, description }: FeatureCardProps) {
  return (
    <motion.div
      className="group -m-3 flex items-start gap-4 rounded-2xl p-3 transition-colors hover:bg-gradient-to-br hover:from-gray-50/95 hover:to-primary/[0.04] md:-m-4 md:p-4"
      whileHover={{ x: 5, transition: { type: "spring", stiffness: 420, damping: 28 } }}
      transition={{ type: "spring", stiffness: 420, damping: 30 }}
    >
      <div className="mt-0.5 flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-primary/18 via-primary/10 to-emerald-500/8 ring-1 ring-primary/25 shadow-md shadow-primary/10 transition-shadow duration-300 group-hover:shadow-lg group-hover:ring-primary/35">
        <Star className="h-5 w-5 text-primary drop-shadow-[0_1px_8px_rgba(0,217,142,0.35)]" strokeWidth={1.5} fill="none" />
      </div>
      <div className="min-w-0">
        <h3 className="font-semibold tracking-tight text-gray-900">{title}</h3>
        <p className="mt-1.5 text-sm leading-relaxed text-gray-600">{description}</p>
      </div>
    </motion.div>
  );
}
