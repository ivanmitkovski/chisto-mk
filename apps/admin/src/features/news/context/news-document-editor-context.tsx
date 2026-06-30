'use client';

import type { Editor } from '@tiptap/react';
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';

type RegisteredEditor = {
  blockId: string;
  blockIndex: number;
  editor: Editor;
};

type NewsDocumentEditorContextValue = {
  activeEditor: Editor | null;
  focusedBlockIndex: number | null;
  toolbarRevision: number;
  registerParagraphEditor: (blockId: string, blockIndex: number, editor: Editor) => void;
  setActiveParagraphEditor: (blockId: string, blockIndex: number, editor: Editor) => void;
  unregisterParagraphEditor: (blockId: string) => void;
  notifyToolbarChange: () => void;
  resolveInsertIndex: (bodyLength: number) => number;
  retainEditorFocus: () => void;
  isRetainingEditorFocus: () => boolean;
};

const NewsDocumentEditorContext = createContext<NewsDocumentEditorContextValue | null>(null);

export function NewsDocumentEditorProvider({ children }: { children: ReactNode }) {
  const [activeEditor, setActiveEditor] = useState<Editor | null>(null);
  const [focusedBlockIndex, setFocusedBlockIndex] = useState<number | null>(null);
  const [toolbarRevision, setToolbarRevision] = useState(0);
  const editorsRef = useRef<Map<string, RegisteredEditor>>(new Map());
  const retainFocusRef = useRef(false);

  const notifyToolbarChange = useCallback(() => {
    setToolbarRevision((value) => value + 1);
  }, []);

  const registerParagraphEditor = useCallback(
    (blockId: string, blockIndex: number, editor: Editor) => {
      editorsRef.current.set(blockId, { blockId, blockIndex, editor });
      setActiveEditor(editor);
      setFocusedBlockIndex(blockIndex);
    },
    [],
  );

  const unregisterParagraphEditor = useCallback((blockId: string) => {
    const removed = editorsRef.current.get(blockId);
    editorsRef.current.delete(blockId);
    setActiveEditor((current) => {
      if (current && removed?.editor === current) {
        const remaining = [...editorsRef.current.values()].sort((a, b) => b.blockIndex - a.blockIndex);
        return remaining[0]?.editor ?? null;
      }
      return current;
    });
    setFocusedBlockIndex((current) => {
      if (removed && removed.blockIndex === current) {
        const remaining = [...editorsRef.current.values()].sort((a, b) => b.blockIndex - a.blockIndex);
        return remaining[0]?.blockIndex ?? null;
      }
      return current;
    });
  }, []);

  const setActiveParagraphEditor = useCallback(
    (blockId: string, blockIndex: number, editor: Editor) => {
      registerParagraphEditor(blockId, blockIndex, editor);
      setToolbarRevision((value) => value + 1);
    },
    [registerParagraphEditor],
  );

  const resolveInsertIndex = useCallback(
    (bodyLength: number) => (focusedBlockIndex !== null ? focusedBlockIndex + 1 : bodyLength),
    [focusedBlockIndex],
  );

  const retainEditorFocus = useCallback(() => {
    retainFocusRef.current = true;
    requestAnimationFrame(() => {
      retainFocusRef.current = false;
    });
  }, []);

  const isRetainingEditorFocus = useCallback(() => retainFocusRef.current, []);

  const value = useMemo(
    () => ({
      activeEditor,
      focusedBlockIndex,
      toolbarRevision,
      registerParagraphEditor,
      setActiveParagraphEditor,
      unregisterParagraphEditor,
      notifyToolbarChange,
      resolveInsertIndex,
      retainEditorFocus,
      isRetainingEditorFocus,
    }),
    [
      activeEditor,
      focusedBlockIndex,
      isRetainingEditorFocus,
      notifyToolbarChange,
      registerParagraphEditor,
      resolveInsertIndex,
      retainEditorFocus,
      setActiveParagraphEditor,
      toolbarRevision,
      unregisterParagraphEditor,
    ],
  );

  return (
    <NewsDocumentEditorContext.Provider value={value}>{children}</NewsDocumentEditorContext.Provider>
  );
}

export function useNewsDocumentEditor(): NewsDocumentEditorContextValue {
  const context = useContext(NewsDocumentEditorContext);
  if (!context) {
    throw new Error('useNewsDocumentEditor must be used within NewsDocumentEditorProvider');
  }
  return context;
}

export function useOptionalNewsDocumentEditor(): NewsDocumentEditorContextValue | null {
  return useContext(NewsDocumentEditorContext);
}
