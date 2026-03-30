"use client";

import { motion } from "framer-motion";
import { fadeInUpTight } from "@/lib/animations/variants";

interface StepCardProps {
  number: number;
  title: string;
  description: string;
}

export function StepCard({ number, title, description }: StepCardProps) {
  return (
    <motion.div
      variants={fadeInUpTight}
      className="relative z-10 flex flex-col items-center text-center"
    >
      <motion.div
        className="relative isolate mb-5 flex h-16 w-16 items-center justify-center rounded-full bg-gradient-to-br from-primary via-primary-500 to-primary-700 text-2xl font-bold tabular-nums text-white shadow-[0_14px_40px_rgba(0,217,142,0.45),inset_0_1px_0_rgba(255,255,255,0.22)] ring-[6px] ring-primary/15 before:pointer-events-none before:absolute before:inset-[-6px] before:-z-10 before:rounded-full before:bg-primary/25 before:blur-md before:content-['']"
        initial={{ scale: 0 }}
        whileInView={{ scale: 1 }}
        viewport={{ once: true, margin: "-40px" }}
        transition={{
          type: "spring",
          stiffness: 260,
          damping: 16,
          delay: number * 0.06,
        }}
      >
        {number}
      </motion.div>
      <h3 className="mb-2 text-xl font-bold tracking-tight text-gray-900">{title}</h3>
      <p className="max-w-[min(100%,20rem)] text-sm leading-relaxed text-gray-600 md:text-base">
        {description}
      </p>
    </motion.div>
  );
}
