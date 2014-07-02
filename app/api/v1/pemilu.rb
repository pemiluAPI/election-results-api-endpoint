module ResultsHelpers
  def get_data_by_province_or_dapil(type, filter, range)
    field = "peringkat_suara_#{filter}"
    field = "peringkat_jumlah_suara" if field == "peringkat_suara_jumlah"
    table = (type == "Province") ? ProvinceVoteTotal : DapilVoteTotal
    if !range.nil?
      arange = range.split('-')
      if arange.count < 2
        arange[0] = arange[1] = range
      end
      results = filter.nil? ? table.where("peringkat_jumlah_suara between #{arange[0]} and #{arange[1]}") : table.where("#{field} between #{arange[0]} and #{arange[1]}")
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
        
        # Prepare conditions based on params
        valid_params = {          
          partai: 'id_partai',          
        }
        conditions = Hash.new
        valid_params.each_pair do |key, value|
          conditions[value.to_sym] = params[key.to_sym] unless params[key.to_sym].blank?
        end
        
        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 1000 : params[:limit]

        search = ["id_dapil LIKE ?", "#{params[:provinsi]}%"]
        
        if (params[:area].downcase == "provinsi")
          get_data_by_province_or_dapil("Province", params[:filter], params[:range])
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
                total: get_data_by_province_or_dapil("Province", params[:filter], params[:range]).count,
                lembaga: 'DPR',
                tahun: '2014',
                area: params[:area] || 'dapil',            
                hasil: results
              }
            }
        elsif ((params[:area].downcase == "dapil" || params[:area].nil?))
          get_data_by_province_or_dapil("Dapil", params[:filter], params[:range])
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
                total: get_data_by_province_or_dapil("Dapil", params[:filter], params[:range]).where(search).count,
                lembaga: 'DPR',
                tahun: '2014',
                area: params[:area] || 'dapil',            
                hasil: results
              }
            }
        end
      end
    end
  end
end