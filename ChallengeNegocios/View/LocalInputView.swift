//
//  LocalInputView.swift
//  ChallengeNegocios
//
//  Created by Alana Queiroz on 25/03/26.
//

import SwiftUI
import MapKit

struct LocalInputView: View {
    @State private var vm = ChecklistViewModel()
    @State private var locService = LocationService()
    @State private var navegarParaLista = false

    var body: some View {
        ZStack(alignment: .bottom) {

            // MARK: Scroll content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Para onde você vai?")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Textinho explicativo.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 24)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Destino")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Onde você deseja ir?", text: $locService.busca)
                                .autocorrectionDisabled()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                        if !locService.sugestoes.isEmpty && locService.busca != vm.destinoSelecionado {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(locService.sugestoes.prefix(5), id: \.self) { sugestao in
                                    Button {
                                        vm.destinoSelecionado = sugestao.title
                                        locService.busca = sugestao.title
                                        locService.sugestoes = []
                                        UIApplication.shared.sendAction(
                                            #selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil
                                        )
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(sugestao.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                            if !sugestao.subtitle.isEmpty {
                                                Text(sugestao.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                    }

                                    if sugestao != locService.sugestoes.prefix(5).last {
                                        Divider().padding(.leading, 14)
                                    }
                                }
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selecione a data")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Ida")
                                Spacer()
                                DatePicker("", selection: $vm.dataIda, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)

                            Divider().padding(.leading, 16)

                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                Text("Volta")
                                Spacer()
                                DatePicker(
                                    "",
                                    selection: $vm.dataVolta,
                                    in: vm.dataIda...,
                                    displayedComponents: .date
                                )
                                .labelsHidden()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 24)
            }

            // MARK: Botão Continuar
            VStack(spacing: 0) {
                Button {
                    navegarParaLista = true
                    Task { await vm.gerarLista() }
                } label: {
                    Text("Gerar")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            vm.destinoSelecionado.isEmpty
                                ? Color(.systemGray4)
                                : Color(.systemGray3)
                        )
                        .foregroundColor(
                            vm.destinoSelecionado.isEmpty ? .secondary : .primary
                        )
                        .cornerRadius(14)
                }
                .disabled(vm.destinoSelecionado.isEmpty)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .background(.ultraThinMaterial)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navegarParaLista) {
            MainChecklistView(vm: vm)
        }
    }
}
