/** Jest stub — production uses real isomorphic-dompurify; tests assert post-sanitize checks. */
const mockPurify = {
  sanitize: (xml: string) => xml,
};

export default mockPurify;
