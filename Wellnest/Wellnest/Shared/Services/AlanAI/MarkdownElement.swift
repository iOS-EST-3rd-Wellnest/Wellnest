//
//  MarkdownElement.swift
//  Wellnest
//
//  Created by junil on 7/31/25.
//

import SwiftUI

// MARK: - Markdown Models
struct MarkdownElement {
    let id = UUID()
    let type: MarkdownType
    let content: String
    let number: Int?

    init(type: MarkdownType, content: String, number: Int? = nil) {
        self.type = type
        self.content = content
        self.number = number
    }
}

enum MarkdownType {
    case header1, header2, header3
    case bold, italic
    case code, codeBlock
    case bulletPoint, numberedPoint
    case normal
}

// MARK: - Improved Markdown Text View
struct ImprovedMarkdownTextView: View {
    let text: String

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(parseImprovedMarkdown(text), id: \.id) { element in
                renderElement(element)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func renderElement(_ element: MarkdownElement) -> some View {
        switch element.type {
        case .header1:
            Text(element.content)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .header2:
            Text(element.content)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .header3:
            Text(element.content)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .bold:
            Text(element.content)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .italic:
            Text(element.content)
                .italic()
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .code:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray4))
                .cornerRadius(4)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .codeBlock:
            Text(element.content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray4))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)

        case .bulletPoint:
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text(element.content)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

        case .numberedPoint:
            HStack(alignment: .top, spacing: 8) {
                Text("\(element.number ?? 1).")
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                VStack(alignment: .leading, spacing: 4) {
                    Text(element.content)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

        case .normal:
            Text(element.content)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 1)
        }
    }
}

// MARK: - Markdown Parser Extension
extension ImprovedMarkdownTextView {
    private func parseImprovedMarkdown(_ text: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        let lines = text.components(separatedBy: .newlines)
        var currentCodeBlock = ""
        var inCodeBlock = false
        var listCounter = 1

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // 빈 줄 처리 - 공백 요소 추가하여 간격 조정
            if trimmedLine.isEmpty {
                listCounter = 1
                continue
            }

            // 코드 블록 처리
            if trimmedLine.hasPrefix("```") {
                if inCodeBlock {
                    if !currentCodeBlock.isEmpty {
                        elements.append(MarkdownElement(
                            type: .codeBlock,
                            content: currentCodeBlock.trimmingCharacters(in: .whitespacesAndNewlines)
                        ))
                    }
                    currentCodeBlock = ""
                    inCodeBlock = false
                } else {
                    inCodeBlock = true
                }
                continue
            }

            if inCodeBlock {
                currentCodeBlock += line + "\n"
                continue
            }

            // 헤더 처리 (순서 중요!)
            if trimmedLine.hasPrefix("### ") {
                let content = String(trimmedLine.dropFirst(4))
                elements.append(MarkdownElement(type: .header3, content: content))
            } else if trimmedLine.hasPrefix("## ") {
                let content = String(trimmedLine.dropFirst(3))
                elements.append(MarkdownElement(type: .header2, content: content))
            } else if trimmedLine.hasPrefix("# ") {
                let content = String(trimmedLine.dropFirst(2))
                elements.append(MarkdownElement(type: .header1, content: content))
            }
            // 불릿 포인트 처리
            else if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                let content = String(trimmedLine.dropFirst(2))
                elements.append(MarkdownElement(type: .bulletPoint, content: content))
                listCounter = 1
            }
            // 숫자 리스트 처리
            else if let range = trimmedLine.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let content = String(trimmedLine[range.upperBound...])
                elements.append(MarkdownElement(
                    type: .numberedPoint,
                    content: content,
                    number: listCounter
                ))
                listCounter += 1
            }
            // 볼드 텍스트 처리 (**text**)
            else if trimmedLine.hasPrefix("**") && trimmedLine.hasSuffix("**") && trimmedLine.count > 4 {
                let content = String(trimmedLine.dropFirst(2).dropLast(2))
                elements.append(MarkdownElement(type: .bold, content: content))
            }
            // 일반 텍스트 처리
            else {
                // 인라인 마크다운 처리
                let processedElements = processInlineMarkdown(trimmedLine)
                elements.append(contentsOf: processedElements)
            }
        }

        return elements
    }

    private func processInlineMarkdown(_ text: String) -> [MarkdownElement] {
        var result: [MarkdownElement] = []
        var currentText = text

        // **볼드** 패턴 찾기
        while let boldRange = currentText.range(of: #"\*\*([^*]+)\*\*"#, options: .regularExpression) {
            // 볼드 앞의 텍스트
            let beforeBold = String(currentText[..<boldRange.lowerBound])
            if !beforeBold.isEmpty {
                result.append(MarkdownElement(type: .normal, content: beforeBold))
            }

            // 볼드 텍스트 추출
            let boldText = String(currentText[boldRange])
            let boldContent = String(boldText.dropFirst(2).dropLast(2))
            result.append(MarkdownElement(type: .bold, content: boldContent))

            // 나머지 텍스트
            currentText = String(currentText[boldRange.upperBound...])
        }

        // 남은 텍스트가 있으면 추가
        if !currentText.isEmpty {
            result.append(MarkdownElement(type: .normal, content: currentText))
        }

        // 결과가 없으면 원본 텍스트를 일반 텍스트로 추가
        if result.isEmpty {
            result.append(MarkdownElement(type: .normal, content: text))
        }

        return result
    }
}
