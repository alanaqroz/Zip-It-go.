//
//  MainChecklistView+PDFExport.swift
//  ChallengeNegocios
//


import SwiftUI

// MARK: - Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uvc: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Export helper
struct DadosExportacaoPDF {
    let destino: String
    let periodo: String
    let estacao: String
    let tempMin: Double?
    let tempMax: Double?
}

func gerarPDF(dados: DadosExportacaoPDF,
              categoriasOrdenadas: [String],
              itensAgrupados: [String: [ItemMala]]) -> URL? {

    let pageWidth: CGFloat  = 595
    let margin:    CGFloat  = 36
    let contentW:  CGFloat  = pageWidth - margin * 2

    let corFundo    = UIColor(red: 0.06, green: 0.04, blue: 0.18, alpha: 1)
    let corAccent   = UIColor(red: 0.71, green: 0.95, blue: 0.24, alpha: 1)
    let corBranco   = UIColor.white
    let corCinza    = UIColor(white: 1, alpha: 0.55)
    let corCard     = UIColor(white: 1, alpha: 0.07)

    func bold(_ size: CGFloat)    -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    func regular(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
    func heavy(_ size: CGFloat)   -> UIFont { .systemFont(ofSize: size, weight: .heavy) }

    var totalH: CGFloat = margin + 80 + 16 + 24 + 16 + 24 + 20 + 32   // header fixo

    for cat in categoriasOrdenadas {
        let itens = itensAgrupados[cat] ?? []
        totalH += 32   // cabeçalho categoria
        totalH += CGFloat(itens.count) * 40
        totalH += 16   // espaço após categoria
    }
    totalH += margin

    // Criar PDF
    let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: totalH)
    let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("ZipIt_PackingList.pdf")

    do {
        try renderer.writePDF(to: tempURL) { ctx in
            ctx.beginPage()
            let cgCtx = ctx.cgContext

            // Fundo
            cgCtx.setFillColor(corFundo.cgColor)
            cgCtx.fill(pageRect)

            var y: CGFloat = margin

            // Título
            let titulo = "Zip It! — Packing List"
            let atTitulo: [NSAttributedString.Key: Any] = [
                .font: heavy(22), .foregroundColor: corBranco
            ]
            titulo.draw(at: CGPoint(x: margin, y: y), withAttributes: atTitulo)
            y += 30

            // Destino
            let destino = dados.destino
            let atDestino: [NSAttributedString.Key: Any] = [
                .font: bold(15), .foregroundColor: corAccent
            ]
            destino.draw(at: CGPoint(x: margin, y: y), withAttributes: atDestino)
            y += 22

            // Período
            let periodo = dados.periodo
            let atPeriodo: [NSAttributedString.Key: Any] = [
                .font: regular(12), .foregroundColor: corCinza
            ]
            periodo.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
            y += 18

            // Clima
            if !dados.estacao.isEmpty {
                let clima: String
                if let tMin = dados.tempMin, let tMax = dados.tempMax {
                    clima = "🌤 \(Int(tMin))°C – \(Int(tMax))°C · \(dados.estacao)"
                } else {
                    clima = "🌤 \(dados.estacao)"
                }
                clima.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
                y += 18
            }

            // Progresso
            let totalItens  = itensAgrupados.values.flatMap { $0 }.count
            let marcados    = itensAgrupados.values.flatMap { $0 }.filter { $0.estaMarcado }.count
            let progresso   = "✓ \(marcados) of \(totalItens) items packed"
            progresso.draw(at: CGPoint(x: margin, y: y), withAttributes: atPeriodo)
            y += 24

            // Linha separadora
            cgCtx.setStrokeColor(UIColor(white: 1, alpha: 0.15).cgColor)
            cgCtx.setLineWidth(0.5)
            cgCtx.move(to: CGPoint(x: margin, y: y))
            cgCtx.addLine(to: CGPoint(x: pageWidth - margin, y: y))
            cgCtx.strokePath()
            y += 20

            // Categorias
            for cat in categoriasOrdenadas {
                let itens = itensAgrupados[cat] ?? []

                // Cabeçalho da categoria
                let marcadosCat = itens.filter { $0.estaMarcado }.count
                let labelCat = "\(cat.uppercased())  \(marcadosCat)/\(itens.count)"
                let atCat: [NSAttributedString.Key: Any] = [
                    .font: bold(11),
                    .foregroundColor: corAccent,
                    .kern: 1.2
                ]
                labelCat.draw(at: CGPoint(x: margin, y: y), withAttributes: atCat)
                y += 22

                // Itens
                for item in itens {
                    // Card de fundo
                    let cardRect = CGRect(x: margin, y: y, width: contentW, height: 32)
                    cgCtx.setFillColor(corCard.cgColor)
                    let path = UIBezierPath(roundedRect: cardRect, cornerRadius: 8)
                    cgCtx.addPath(path.cgPath)
                    cgCtx.fillPath()

                    // Checkbox
                    let boxSize: CGFloat = 14
                    let boxRect = CGRect(x: margin + 10, y: y + 9, width: boxSize, height: boxSize)
                    if item.estaMarcado {
                        cgCtx.setFillColor(corAccent.cgColor)
                        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 3)
                        cgCtx.addPath(boxPath.cgPath)
                        cgCtx.fillPath()
                        // Check mark
                        let atCheck: [NSAttributedString.Key: Any] = [
                            .font: bold(9), .foregroundColor: UIColor.black
                        ]
                        "✓".draw(at: CGPoint(x: margin + 12, y: y + 10), withAttributes: atCheck)
                    } else {
                        cgCtx.setStrokeColor(UIColor(white: 1, alpha: 0.3).cgColor)
                        cgCtx.setLineWidth(1)
                        let boxPath = UIBezierPath(roundedRect: boxRect, cornerRadius: 3)
                        cgCtx.addPath(boxPath.cgPath)
                        cgCtx.strokePath()
                    }

                    // Nome do item
                    let atItem: [NSAttributedString.Key: Any] = [
                        .font: regular(12),
                        .foregroundColor: item.estaMarcado ? corCinza : corBranco
                    ]
                    item.nomeApenas.draw(at: CGPoint(x: margin + 34, y: y + 10), withAttributes: atItem)

                    // Quantidade
                    let qty = "×\(item.quantidade)"
                    let atQty: [NSAttributedString.Key: Any] = [
                        .font: regular(11), .foregroundColor: corCinza
                    ]
                    let qtyW = (qty as NSString).size(withAttributes: atQty).width
                    qty.draw(at: CGPoint(x: pageWidth - margin - qtyW - 10, y: y + 11),
                             withAttributes: atQty)

                    y += 40
                }

                y += 16   // espaço após categoria
            }

            // Rodapé 
            let rodape = "Generated by Zip It!"
            let atRodape: [NSAttributedString.Key: Any] = [
                .font: regular(9), .foregroundColor: corCinza
            ]
            let rodapeW = (rodape as NSString).size(withAttributes: atRodape).width
            rodape.draw(at: CGPoint(x: (pageWidth - rodapeW) / 2, y: y + 8),
                        withAttributes: atRodape)
        }
        return tempURL
    } catch {
        print("Erro ao gerar PDF: \(error)")
        return nil
    }
}
