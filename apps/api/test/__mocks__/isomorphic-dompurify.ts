const mockPurify = {
  sanitize: (xml: string) => {
    if (/<script/i.test(xml)) {
      return xml.replace(/<script[\s\S]*?<\/script>/gi, '');
    }
    return xml;
  },
};

export default mockPurify;
