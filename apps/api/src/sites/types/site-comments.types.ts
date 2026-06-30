export type SiteCommentTreeNode = {
  id: string;
  parentId: string | null;
  body: string;
  createdAt: string;
  authorId: string | null;
  authorName: string;
  authorIsDeleted?: boolean;
  authorAvatarUrl?: string | null;
  likesCount: number;
  isLikedByMe: boolean;
  replies: SiteCommentTreeNode[];
  repliesCount: number;
};
