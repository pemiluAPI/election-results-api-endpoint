module ResultsHelpers
  def get_data_by_province_or_dapil(type, filter, range)
    field = "peringkat_suara_#{filter}"
    field = "peringkat_jumlah_suara" if field == "peringkat_suara_jumlah"
    table = (type == "provinsi") ? ProvinceVoteTotal : DapilVoteTotal
    if !range.nil?
      arange = range.split('-')
      
      arange[0] = arange[1] = range if arange.count < 2
      
      #results = filter.nil? ? table.where("peringkat_jumlah_suara between ? and ?", arange[0], arange[1]).group("id_#{type},id_partai").order("peringkat_jumlah_suara,id_#{type}") : table.where("#{field} between ? and ?", arange[0], arange[1]).group("id_#{type},id_partai").order("#{field},id_#{type}")
      results = filter.nil? ? table.where("peringkat_jumlah_suara between ? and ?", arange[0], arange[1]).order("id_#{type}") : table.where("#{field} between ? and ?", arange[0], arange[1]).order("id_#{type}")
    else
      results = table
    end
    results    
  end  
end

module Pemilu
  class APIv1 < Grape::API
    version 'v1', using: :accept_version_header
    prefix 'api'
    format :json

    resource :hasil_legislatif do
      helpers ResultsHelpers
      
      desc "Return all Legislatif Results"
      get do
        results = Array.new
        
        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 1000 : params[:limit]

        search = ["substr(id_dapil,1,2) = ?", "#{params[:provinsi]}"] unless params[:provinsi].nil?
        
        if (params[:area].nil?)
          get_data_by_province_or_dapil("dapil", params[:filter], params[:range])
          .limit(limit)
          .offset(params[:offset])
          .where(search)
          .each do |result|
            results << {
              dapil: {
                id: result.id_dapil,
                nama: result.nama_dapil
              },
              partai: {
                id: result.id_partai,
                nama: result.nama_partai
              },
              suara_calon_terpilih: result.suara_calon_terpilih,
              peringkat_suara_calon_terpilih: result.peringkat_suara_calon_terpilih,
              suara_calon_semua: result.suara_calon_semua,
              peringkat_suara_calon_semua: result.peringkat_suara_calon_semua,
              suara_partai: result.suara_partai,
              peringkat_suara_partai: result.peringkat_suara_partai,
              jumlah_suara: result.jumlah_suara,
              peringkat_jumlah_suara: result.peringkat_jumlah_suara,
            }
          end
          {
            results: {
              count: results.count,
              total: get_data_by_province_or_dapil("dapil", params[:filter], params[:range]).where(search).count,
              lembaga: 'DPR',
              tahun: '2014',
              area: 'dapil',
              hasil: results
            }
          }
        else
          if (params[:area].downcase == "provinsi")
            get_data_by_province_or_dapil("provinsi", params[:filter], params[:range])
            .limit(limit)
            .offset(params[:offset])
            .each do |result|
              results << {
                provinsi: {
                  id: result.id_provinsi,
                  nama: result.nama_provinsi
                },
                partai: {
                  id: result.id_partai,
                  nama: result.nama_partai
                },
                suara_calon_terpilih: result.suara_calon_terpilih,
                peringkat_suara_calon_terpilih: result.peringkat_suara_calon_terpilih,
                suara_calon_semua: result.suara_calon_semua,
                peringkat_suara_calon_semua: result.peringkat_suara_calon_semua,
                suara_partai: result.suara_partai,
                peringkat_suara_partai: result.peringkat_suara_partai,
                jumlah_suara: result.jumlah_suara,
                peringkat_jumlah_suara: result.peringkat_jumlah_suara,
              }
            end
            {
              results: {
                count: results.count,
                total: get_data_by_province_or_dapil("provinsi", params[:filter], params[:range]).count,
                lembaga: 'DPR',
                tahun: '2014',
                area: params[:area].downcase,
                hasil: results
              }
            }
          elsif (params[:area].downcase == "dapil")
            get_data_by_province_or_dapil("dapil", params[:filter], params[:range])
            .limit(limit)
            .offset(params[:offset])
            .where(search)
            .each do |result|
              results << {
                dapil: {
                  id: result.id_dapil,
                  nama: result.nama_dapil
                },
                partai: {
                  id: result.id_partai,
                  nama: result.nama_partai
                },
                suara_calon_terpilih: result.suara_calon_terpilih,
                peringkat_suara_calon_terpilih: result.peringkat_suara_calon_terpilih,
                suara_calon_semua: result.suara_calon_semua,
                peringkat_suara_calon_semua: result.peringkat_suara_calon_semua,
                suara_partai: result.suara_partai,
                peringkat_suara_partai: result.peringkat_suara_partai,
                jumlah_suara: result.jumlah_suara,
                peringkat_jumlah_suara: result.peringkat_jumlah_suara,
              }
            end
            {
              results: {
                count: results.count,
                total: get_data_by_province_or_dapil("dapil", params[:filter], params[:range]).where(search).count,
                lembaga: 'DPR',
                tahun: '2014',
                area: params[:area].downcase,
                hasil: results
              }
            }
          else
            {
              results: {
                count: 0,
                total: 0,
                lembaga: 'DPR',
                tahun: '2014',
                area: params[:area].downcase,
                hasil: []
              }
            }
          end
        end
      end
    end
  end
end